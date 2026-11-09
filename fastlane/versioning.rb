# Version and build number live in project.yml (XcodeGen is the source of truth):
#   MARKETING_VERSION: "1.0"        → CFBundleShortVersionString, the version users see
#   CURRENT_PROJECT_VERSION: "1"    → CFBundleVersion, the build number
# The build number goes up by one after every TestFlight upload and back to 1 with a new version.
# Apple allows that: a build number must be new only within one version.
module MediantVersion
  VERSION_LINE = /^(\s*MARKETING_VERSION:\s*)"([^"]+)"/
  BUILD_LINE = /^(\s*CURRENT_PROJECT_VERSION:\s*)"(\d+)"/
  VERSION_FORMAT = /\A\d+(\.\d+){1,2}\z/

  def self.read(text)
    version = text[VERSION_LINE, 2] or raise ArgumentError, "MARKETING_VERSION not found in project.yml"
    build = text[BUILD_LINE, 2] or raise ArgumentError, "CURRENT_PROJECT_VERSION not found in project.yml"
    { version: version, build: Integer(build, 10) }
  end

  # The same text with the next build number.
  def self.next_build(text)
    build = read(text)[:build] + 1
    text.sub(BUILD_LINE) { "#{Regexp.last_match(1)}\"#{build}\"" }
  end

  # The same text with a new, higher version and build number 1.
  def self.new_version(text, version)
    version = version.to_s.strip
    raise ArgumentError, "Version must look like 1.1 or 1.1.2, not #{version.inspect}" unless version.match?(VERSION_FORMAT)
    current = read(text)[:version]
    unless Gem::Version.new(version) > Gem::Version.new(current)
      raise ArgumentError, "Version #{version} is not higher than the current #{current}"
    end
    text.sub(VERSION_LINE) { "#{Regexp.last_match(1)}\"#{version}\"" }
        .sub(BUILD_LINE) { "#{Regexp.last_match(1)}\"1\"" }
  end
end
