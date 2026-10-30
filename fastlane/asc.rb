require "digest"
require "json"
require "net/http"
require "uri"
require "spaceship"

# App Store Connect API for the tip in-app purchases. fastlane's Spaceship has no models for
# in-app purchases (v2 API), so this talks to the API directly and only borrows Spaceship's JWT.
module MediantASC
  class APIError < StandardError
    attr_reader :status

    def initialize(status, message)
      @status = status
      super(message)
    end
  end

  class Client
    HOST = "https://api.appstoreconnect.apple.com".freeze

    def initialize(key_id:, issuer_id:, key_path:)
      @token = Spaceship::ConnectAPI::Token.create(
        key_id: key_id, issuer_id: issuer_id, filepath: File.expand_path(key_path)
      )
    end

    def get(path, params = {})
      request(Net::HTTP::Get, path, params: params)
    end

    # Every page of a list endpoint, following `links.next`.
    def all(path, params = {})
      items = []
      page = get(path, params)
      loop do
        items.concat(page["data"])
        next_url = page.dig("links", "next")
        break unless next_url
        page = get(next_url)
      end
      items
    end

    # nil instead of an error when the resource does not exist yet.
    def find(path, params = {})
      get(path, params)
    rescue APIError => e
      raise unless e.status == 404
      nil
    end

    def post(path, body)
      request(Net::HTTP::Post, path, body: body)
    end

    def patch(path, body)
      request(Net::HTTP::Patch, path, body: body)
    end

    def delete(path)
      request(Net::HTTP::Delete, path)
    end

    # Sends a file through the upload operations App Store Connect returns for a reserved asset.
    # These go to Apple's upload URLs, which take no Authorization header.
    def upload(operations, data)
      operations.each do |op|
        uri = URI(op["url"])
        req = Net::HTTPGenericRequest.new(op["method"], true, true, uri)
        (op["requestHeaders"] || []).each { |header| req[header["name"]] = header["value"] }
        req.body = data.byteslice(op["offset"], op["length"])
        res = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(req) }
        raise APIError.new(res.code.to_i, "upload #{uri.host} → #{res.code}") unless res.is_a?(Net::HTTPSuccess)
      end
    end

    private

    def request(method, path, params: {}, body: nil)
      uri = URI(path.start_with?("http") ? path : HOST + path)
      uri.query = URI.encode_www_form(params) unless params.empty?
      @token.refresh! if @token.expired?

      req = method.new(uri)
      req["Authorization"] = "Bearer #{@token.text}"
      if body
        req["Content-Type"] = "application/json"
        req.body = body.to_json
      end
      res = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |http| http.request(req) }
      json = res.body.to_s.empty? ? {} : JSON.parse(res.body)
      return json if res.is_a?(Net::HTTPSuccess)

      details = (json["errors"] || []).map { |e| "#{e['title']}: #{e['detail']}" }
      raise APIError.new(res.code.to_i, "#{method::METHOD} #{uri.path} → #{res.code}\n  #{details.join("\n  ")}")
    end
  end

  # Makes App Store Connect match fastlane/tips.json: creates missing tips and fixes names,
  # descriptions, review note, price, promotional image and App Review screenshot. Availability is set once (all
  # territories) and then left alone. A tip is never deleted: a deleted product ID can never be
  # used again. Image paths in the config are relative to `dir`.
  class Tips
    def initialize(client:, config:, ui:, dir:)
      @client = client
      @config = config
      @ui = ui
      @dir = dir
    end

    def sync(dry_run: false)
      @dry_run = dry_run
      app = @client.get("/v1/apps", "filter[bundleId]" => @config["bundle_id"])["data"].first
      @ui.user_error!("No app #{@config['bundle_id']} in App Store Connect") unless app

      existing = @client.all("/v1/apps/#{app['id']}/inAppPurchasesV2", "limit" => 200)
                        .to_h { |iap| [iap.dig("attributes", "productId"), iap] }

      @config["tips"].each do |tip|
        iap = existing[tip["product_id"]]
        iap = iap ? update_iap(iap, tip) : create_iap(app, tip)
        next unless iap

        sync_localizations(iap, tip)
        sync_price(iap, tip)
        sync_availability(iap)
        sync_image(iap, tip)
        sync_review_screenshot(iap, tip)
        @ui.message("#{tip['product_id']}: #{iap.dig('attributes', 'state')}")
      end
    end

    private

    def change(text)
      @ui.important("#{@dry_run ? '[dry run] would ' : ''}#{text}")
      yield unless @dry_run
    end

    def create_iap(app, tip)
      created = nil
      change("create #{tip['product_id']} (#{tip['reference_name']}, $#{tip['price']})") do
        created = @client.post("/v2/inAppPurchases", data: {
          type: "inAppPurchases",
          attributes: {
            name: tip["reference_name"],
            productId: tip["product_id"],
            inAppPurchaseType: "CONSUMABLE",
            reviewNote: @config["review_note"]
          },
          relationships: { app: { data: { type: "apps", id: app["id"] } } }
        })["data"]
      end
      created
    end

    def update_iap(iap, tip)
      attrs = iap["attributes"]
      wanted = { "name" => tip["reference_name"], "reviewNote" => @config["review_note"] }
      diff = wanted.reject { |key, value| attrs[key] == value }
      return iap if diff.empty?

      change("update #{tip['product_id']}: #{diff.keys.join(', ')}") do
        iap = @client.patch("/v2/inAppPurchases/#{iap['id']}", data: {
          type: "inAppPurchases", id: iap["id"], attributes: diff
        })["data"]
      end
      iap
    end

    def sync_localizations(iap, tip)
      current = @client.all("/v2/inAppPurchases/#{iap['id']}/inAppPurchaseLocalizations")
                       .to_h { |loc| [loc.dig("attributes", "locale"), loc] }

      tip["localizations"].each do |locale, texts|
        loc = current[locale]
        if loc.nil?
          change("add #{locale} to #{tip['product_id']}: #{texts['name']}") do
            @client.post("/v1/inAppPurchaseLocalizations", data: {
              type: "inAppPurchaseLocalizations",
              attributes: { locale: locale, name: texts["name"], description: texts["description"] },
              relationships: { inAppPurchaseV2: { data: { type: "inAppPurchases", id: iap["id"] } } }
            })
          end
        elsif loc.dig("attributes", "name") != texts["name"] ||
              loc.dig("attributes", "description") != texts["description"]
          change("update #{locale} of #{tip['product_id']}: #{texts['name']}") do
            @client.patch("/v1/inAppPurchaseLocalizations/#{loc['id']}", data: {
              type: "inAppPurchaseLocalizations", id: loc["id"],
              attributes: { name: texts["name"], description: texts["description"] }
            })
          end
        end
      end
    end

    def sync_price(iap, tip)
      territory = @config["base_territory"]
      return if current_price(iap, territory)&.to_f == tip["price"].to_f

      point = @client.all("/v2/inAppPurchases/#{iap['id']}/pricePoints",
                          "filter[territory]" => territory, "limit" => 200)
                     .find { |p| p.dig("attributes", "customerPrice").to_f == tip["price"].to_f }
      @ui.user_error!("No #{territory} price point #{tip['price']} for #{tip['product_id']}") unless point

      change("set #{tip['product_id']} price to #{tip['price']} (#{territory}, others follow)") do
        @client.post("/v1/inAppPurchasePriceSchedules", {
          data: {
            type: "inAppPurchasePriceSchedules",
            relationships: {
              inAppPurchase: { data: { type: "inAppPurchases", id: iap["id"] } },
              baseTerritory: { data: { type: "territories", id: territory } },
              manualPrices: { data: [{ type: "inAppPurchasePrices", id: "${price}" }] }
            }
          },
          included: [{
            type: "inAppPurchasePrices", id: "${price}",
            attributes: { startDate: nil },
            relationships: {
              inAppPurchaseV2: { data: { type: "inAppPurchases", id: iap["id"] } },
              inAppPurchasePricePoint: { data: { type: "inAppPurchasePricePoints", id: point["id"] } }
            }
          }]
        })
      end
    end

    # The customer price in the base territory, or nil when no price is set yet.
    def current_price(iap, territory)
      prices = @client.find("/v1/inAppPurchasePriceSchedules/#{iap['id']}/manualPrices",
                            "include" => "inAppPurchasePricePoint,territory",
                            "filter[territory]" => territory)
      return nil unless prices

      point_id = prices["data"].first&.dig("relationships", "inAppPurchasePricePoint", "data", "id")
      (prices["included"] || []).find { |item| item["type"] == "inAppPurchasePricePoints" && item["id"] == point_id }
                                &.dig("attributes", "customerPrice")
    end

    # The promotional image (1024×1024) shown when the tip is promoted on the App Store. An image
    # with the same MD5 stays; a different one is replaced.
    def sync_image(iap, tip)
      return unless tip["image"]

      path = File.join(@dir, tip["image"])
      data = File.binread(path)
      checksum = Digest::MD5.hexdigest(data)
      current = @client.all("/v2/inAppPurchases/#{iap['id']}/images")
      return if current.any? { |image| image.dig("attributes", "sourceFileChecksum") == checksum }

      verb = current.empty? ? "upload" : "replace"
      change("#{verb} image of #{tip['product_id']}: #{tip['image']}") do
        current.each { |image| @client.delete("/v1/inAppPurchaseImages/#{image['id']}") }
        reserved = @client.post("/v1/inAppPurchaseImages", data: {
          type: "inAppPurchaseImages",
          attributes: { fileName: File.basename(path), fileSize: data.bytesize },
          relationships: { inAppPurchase: { data: { type: "inAppPurchases", id: iap["id"] } } }
        })["data"]
        @client.upload(reserved.dig("attributes", "uploadOperations"), data)
        @client.patch("/v1/inAppPurchaseImages/#{reserved['id']}", data: {
          type: "inAppPurchaseImages", id: reserved["id"],
          attributes: { sourceFileChecksum: checksum, uploaded: true }
        })
      end
    end

    # The App Review screenshot of the screen where the tip is bought (Apple wants it before the
    # first submission). One per tip; the same MD5 stays, a different file is replaced.
    def sync_review_screenshot(iap, tip)
      return unless tip["review_screenshot"]

      path = File.join(@dir, tip["review_screenshot"])
      data = File.binread(path)
      checksum = Digest::MD5.hexdigest(data)
      current = @client.find("/v2/inAppPurchases/#{iap['id']}/appStoreReviewScreenshot")&.dig("data")
      return if current && current.dig("attributes", "sourceFileChecksum") == checksum

      verb = current ? "replace" : "upload"
      change("#{verb} review screenshot of #{tip['product_id']}: #{tip['review_screenshot']}") do
        @client.delete("/v1/inAppPurchaseAppStoreReviewScreenshots/#{current['id']}") if current
        reserved = @client.post("/v1/inAppPurchaseAppStoreReviewScreenshots", data: {
          type: "inAppPurchaseAppStoreReviewScreenshots",
          attributes: { fileName: File.basename(path), fileSize: data.bytesize },
          relationships: { inAppPurchaseV2: { data: { type: "inAppPurchases", id: iap["id"] } } }
        })["data"]
        @client.upload(reserved.dig("attributes", "uploadOperations"), data)
        @client.patch("/v1/inAppPurchaseAppStoreReviewScreenshots/#{reserved['id']}", data: {
          type: "inAppPurchaseAppStoreReviewScreenshots", id: reserved["id"],
          attributes: { sourceFileChecksum: checksum, uploaded: true }
        })
      end
    end

    def sync_availability(iap)
      return if @client.find("/v2/inAppPurchases/#{iap['id']}/inAppPurchaseAvailability")&.dig("data")

      territories = @client.all("/v1/territories", "limit" => 200)
      change("make #{iap.dig('attributes', 'productId')} available in #{territories.count} territories") do
        @client.post("/v1/inAppPurchaseAvailabilities", data: {
          type: "inAppPurchaseAvailabilities",
          attributes: { availableInNewTerritories: true },
          relationships: {
            inAppPurchase: { data: { type: "inAppPurchases", id: iap["id"] } },
            availableTerritories: { data: territories.map { |t| { type: "territories", id: t["id"] } } }
          }
        })
      end
    end
  end
end
