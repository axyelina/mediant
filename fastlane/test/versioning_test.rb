# Run: ruby fastlane/test/versioning_test.rb
require "minitest/autorun"
require_relative "../versioning"

class VersioningTest < Minitest::Test
  YML = <<~YML
    settings:
      base:
        MARKETING_VERSION: "1.0"
        DEVELOPMENT_TEAM: NDCC8HH7D8
        CURRENT_PROJECT_VERSION: "7"
  YML

  def test_read
    assert_equal({ version: "1.0", build: 7 }, MediantVersion.read(YML))
  end

  def test_next_build_changes_only_the_build_number
    text = MediantVersion.next_build(YML)
    assert_equal({ version: "1.0", build: 8 }, MediantVersion.read(text))
    assert_equal YML.sub('"7"', '"8"'), text
  end

  def test_next_build_past_nine
    text = MediantVersion.next_build(YML.sub('"7"', '"9"'))
    assert_equal 10, MediantVersion.read(text)[:build]
  end

  def test_new_version_resets_the_build_number
    text = MediantVersion.new_version(YML, "1.1")
    assert_equal({ version: "1.1", build: 1 }, MediantVersion.read(text))
    assert_includes text, "DEVELOPMENT_TEAM: NDCC8HH7D8"
  end

  def test_new_version_accepts_three_parts
    assert_equal "1.0.1", MediantVersion.read(MediantVersion.new_version(YML, " 1.0.1 "))[:version]
  end

  def test_new_version_must_be_higher
    assert_raises(ArgumentError) { MediantVersion.new_version(YML, "1.0") }
    assert_raises(ArgumentError) { MediantVersion.new_version(YML, "0.9") }
  end

  def test_new_version_must_be_numbers
    assert_raises(ArgumentError) { MediantVersion.new_version(YML, "1.1-beta") }
    assert_raises(ArgumentError) { MediantVersion.new_version(YML, "2") }
  end

  def test_missing_lines
    assert_raises(ArgumentError) { MediantVersion.read("settings: {}") }
  end

  def test_real_project_yml
    real = File.read(File.expand_path("../../project.yml", __dir__))
    info = MediantVersion.read(real)
    assert_match MediantVersion::VERSION_FORMAT, info[:version]
    assert_operator info[:build], :>=, 1
  end
end
