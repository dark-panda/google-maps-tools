# encoding: UTF-8

$: << File.dirname(__FILE__)
require 'test_helper'

class GoogleMapsGeocoderResponseTest
  %w{
    hot_springs_national_park.json
    macomb_mi.json
    new_jersey.json
    north_york_on.json
    richmond_va.json
    squamish_bc.json
    sun_valley_la_ca.json
    toronto_on.json
  }.each do |file|
    self.const_set(
      "#{file.sub(/\.json$/, '')}".upcase,
      GoogleMapsTools::GeocoderResponse.new(
        JSON.load(
          File.read(File.join(File.dirname(__FILE__), %W{ geocoder_responses #{file} }))
        )
      )
    )
  end

  class ShortNamesTest < MiniTest::Unit::TestCase
    def test_establishments_parks
      assert_equal("Hot Springs National Park", HOT_SPRINGS_NATIONAL_PARK.short_name)
    end

    def test_counties
      assert_equal("Macomb", MACOMB_MI.short_name)
    end

    def test_provinces_states
      assert_equal("New Jersey", NEW_JERSEY.short_name)
    end

    def test_colloqiual_area_names
      assert_equal("Richmond", RICHMOND_VA.short_name)
    end

    def test_sublocalities
      assert_equal("North York", NORTH_YORK_ON.short_name)
    end

    def test_minor_civil_divisions
      assert_equal("Squamish", SQUAMISH_BC.short_name)
    end

    def test_neighborhoods
      assert_equal("Sun Valley", SUN_VALLEY_LA_CA.short_name)
    end

    def test_localities
      assert_equal("Toronto", TORONTO_ON.short_name)
    end
  end

  class LongNamesTest < MiniTest::Unit::TestCase
    def test_establishments_parks
      assert_equal("Hot Springs National Park, Hot Springs, AR", HOT_SPRINGS_NATIONAL_PARK.long_name)
    end

    def test_counties_administrative_area_level_2
      assert_equal("Macomb, MI", MACOMB_MI.long_name)
    end

    def test_provinces_states_administrative_area_level_1
      assert_equal("New Jersey", NEW_JERSEY.long_name)
    end

    def test_colloquial_area_names
      assert_equal("Richmond, VA", RICHMOND_VA.long_name)
    end

    def test_sublocalities
      assert_equal("North York, ON", NORTH_YORK_ON.long_name)
    end

    def test_minor_civil_divisions_administrative_area_level_2
      assert_equal("Squamish, BC", SQUAMISH_BC.long_name)
    end

    def test_neighborhoods
      assert_equal("Sun Valley, Los Angeles, CA", SUN_VALLEY_LA_CA.long_name)
    end

    def test_localities
      assert_equal("Toronto, ON", TORONTO_ON.long_name)
    end
  end

  class MiscTest < MiniTest::Unit::TestCase
    def test_as_json
      skip unless defined?(JSON)

      json = JSON.dump(MACOMB_MI)
      assert_equal(JSON.load(json), MACOMB_MI.geocode)
    end
  end
end

