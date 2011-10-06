
require 'test/unit'
require File.join(File.dirname(__FILE__), %w{ .. lib google_maps_tools })

begin
  require 'ffi-geos'
rescue LoadError
end

class ValidatesQuadTreeTest < Test::Unit::TestCase
  include GoogleMapsTools::QuadTree

  def test_from_quad_tree_to_lat_lng_bounds
    quad_trees = [
       '0302303222103200302122'
    ]
    lat_lngs = [
      [
        [ 0.0, -180.0, 85.0511287798066, 0.0 ],
        [ 0.0, -90.0, 66.5132604431118, 0.0 ],
        [ 40.9798980696202, -90.0, 66.5132604431118, -45.0 ],
        [ 40.9798980696202, -90.0, 55.7765730186677, -67.5 ],
        [ 40.9798980696202, -78.75, 48.9224992637583, -67.5 ],
        [ 45.089035564831, -78.75, 48.9224992637583, -73.125 ],
        [ 45.089035564831, -75.9375, 47.0401821448067, -73.125 ],
        [ 45.089035564831, -75.9375, 46.0732306254083, -74.53125 ],
        [ 45.089035564831, -75.9375, 45.5832897560063, -75.234375 ],
        [ 45.089035564831, -75.9375, 45.3367019099681, -75.5859375 ],
        [ 45.213003555994, -75.76171875, 45.3367019099681, -75.5859375 ],
        [ 45.2748864370489, -75.76171875, 45.3367019099681, -75.673828125 ],
        [ 45.2748864370489, -75.7177734375, 45.3058025994358, -75.673828125 ],
        [ 45.2748864370489, -75.7177734375, 45.2903466247361, -75.69580078125 ],
        [ 45.2826170575174, -75.7177734375, 45.2903466247361, -75.706787109375 ],
        [ 45.2864819727828, -75.7177734375, 45.2903466247361, -75.7122802734375 ],
        [ 45.2864819727828, -75.7150268554688, 45.2884143316735, -75.7122802734375 ],
        [ 45.2874481604566, -75.7150268554688, 45.2884143316735, -75.7136535644531 ],
        [ 45.2874481604566, -75.7150268554688, 45.2879312481222, -75.714340209961 ],
        [ 45.2876897048037, -75.7146835327149, 45.2879312481222, -75.714340209961 ]
      ]
    ]

    quad_trees.each_with_index do |qt, i|
      0.upto(19) do |z|
        from_quad_tree_to_lat_lng_bounds(qt[0..z]).each_with_index do |ll, ii|
          assert_in_delta(ll, lat_lngs[i][z][ii], 1.0e8)
        end
      end
    end
  end

  def test_from_lng_lat_to_quad_tree
    lng_lats = [
      [ -62.485545, 44.951397 ],
      [ -112.860978, 49.664716 ],
      [ -79.667565, 43.583514 ],
      [ -63.643128, 46.285669 ],
      [ -79.849052, 43.51968 ]
    ]
    quad_trees = [
      '0303221110210022132',
      '0212133310331110230',
      '0302231303233222113',
      '0303203032113110002',
      '0302231320112333113'
    ]

    lng_lats.each_with_index do |ll, i|
      assert_equal(from_lng_lat_to_quad_tree(*(ll << 19)), quad_trees[i])
    end
  end

  def test_from_lat_lng_to_quad_tree
    lat_lngs = [
      [ 44.951397, -62.485545 ],
      [ 49.664716, -112.860978 ],
      [ 43.583514, -79.667565 ],
      [ 46.285669, -63.643128 ],
      [ 43.51968, -79.849052 ]
    ]
    quad_trees = [
      '0303221110210022132',
      '0212133310331110230',
      '0302231303233222113',
      '0303203032113110002',
      '0302231320112333113'
    ]

    lat_lngs.each_with_index do |ll, i|
      assert_equal(from_lat_lng_to_quad_tree(*(ll << 19)), quad_trees[i])
    end
  end

  def test_from_quad_tree_to_tile
    quad_trees = [
      '0303221110210022132'
    ]
    tiles = [
      [
        [ 0, 0 ],
        [ 0, 1 ],
        [ 1, 2 ],
        [ 2, 5 ],
        [ 5, 10 ],
        [ 10, 20 ],
        [ 20, 40 ],
        [ 41, 81 ],
        [ 83, 163 ],
        [ 167, 327 ],
        [ 334, 655 ],
        [ 668, 1310 ],
        [ 1337, 2621 ],
        [ 2674, 5243 ],
        [ 5348, 10487 ],
        [ 10696, 20974 ],
        [ 21392, 41948 ],
        [ 42785, 83897 ],
        [ 85571, 167794 ],
        [ 171142, 335588 ]
      ]
    ]

    quad_trees.each_with_index do |qt, i|
      0.upto(qt.length) do |z|
        assert_equal(from_quad_tree_to_tile(qt, z), tiles[i][z])
      end
    end
  end

  def test_from_geos_to_quad_tree
    geoms = [
      [ '010100000000000000000000000000000000000000', 19 ],
      [ Geos::WktReader.new.read('POINT(-79.667565 43.583514)'), 19 ],
      [ 'POINT(-79.667565 43.583514)', 19 ]
    ]
    expected = [
      '2111111111111111111',
      '0302231303233222113',
      '0302231303233222113'
    ]

    geoms.each_with_index do |g, i|
      assert_equal(
        from_geos_to_quad_tree(*g),
        expected[i]
      )
    end
  end
end