# encoding: UTF-8

$: << File.dirname(__FILE__)
require 'test_helper'
require 'yaml'

class Marker < Struct.new(:id, :quad_tree, :lng, :lat)
end

class ValidatesMarkerClustererTest < MiniTest::Unit::TestCase
  MAX_ZOOM = 22

  MARKERS = YAML.load(
    File.read(
      File.join(
        File.dirname(__FILE__),
        'markers.yml'
      )
    )
  )

  EXPECTED_CLUSTERS_AND_SINGLES_COUNTS = [
    [ 21, 95 ],
    [ 21, 95 ],
    [ 21, 95 ],
    [ 21, 95 ],
    [ 21, 95 ],
    [ 23, 91 ],
    [ 23, 91 ],
    [ 24, 89 ],
    [ 25, 82 ],
    [ 31, 63 ],
    [ 34, 44 ],
    [ 35, 29 ],
    [ 27, 16 ],
    [ 21, 5 ],
    [ 12, 0 ],
    [ 6, 0 ],
    [ 2, 0 ],
    [ 1, 0 ],
    [ 1, 0 ],
    [ 1, 0 ],
    [ 1, 0 ],
    [ 1, 0 ],
    [ 1, 0 ]
  ]

  def test_with_constructor
    markers = MARKERS.collect do |m|
      Marker.new(*m)
    end

    MAX_ZOOM.downto(0) do |zoom|
      c = GoogleMapsTools::MarkerClusterer.new(markers, zoom)
      assert_equal([ c.clusters.length, c.singles.length ], EXPECTED_CLUSTERS_AND_SINGLES_COUNTS[MAX_ZOOM - zoom])
    end
  end
end
