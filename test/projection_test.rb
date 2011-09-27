
require 'test/unit'
require File.join(File.dirname(__FILE__), %w{ .. lib google_maps_tools })

begin
	require 'ffi-geos'
rescue LoadError
end

class ValidatesProjectionTest < Test::Unit::TestCase
	include GoogleMapsTools::Projection

	def test_from_geos_to_pixel
		if defined?(Geos)
			geoms = [
				[ '010100000000000000000000000000000000000000', 0 ],
				[ Geos::WktReader.new.read('POINT(32768 -1234567890)'), 21 ]
			]
			expected = [
				'010100000000000000000060400000000000006040',
				'01010000000000C2166CE12642000000CE049CC441'
			]

			geoms.each_with_index do |g, i|
				assert_equal(
					Geos::WkbWriter.new.write_hex(from_geos_to_pixel(*g)),
					expected[i]
				)
			end
		end
	end

	def test_from_lng_lat_to_pixel
		lng_lats = [
			[ 0, 0, 0 ],
			[ -45, 45, 1 ],
			[ -79.337, 43.729, 10 ]
		]

		pixels = [
			[ 128, 128 ],
			[ 192, 184 ],
			[ 73301, 95594 ]
		]

		lng_lats.each_with_index do |ll, i|
			assert_equal(from_lng_lat_to_pixel(*ll), pixels[i])
		end
	end

	def test_from_pixel_to_lng_lat
		lng_lats = [
			[ 0, 0 ],
			[ -45, 45 ],
			[ -79.337, 43.729 ]
		]

		pixels = [
			[ 128, 128, 0 ],
			[ 192, 184, 1 ],
			[ 73301, 95594, 10 ]
		]

		pixels.each_with_index do |px, i|
			from_pixel_to_lng_lat(*px).each_with_index do |j, ii|
				assert_in_delta(lng_lats[i][ii], j, 0.1)
			end
		end
	end

	def test_from_pixel_to_tile
		pixels = [
			[ 0, 0 ],
			[ 100, 100 ],
			[ 314159, 314159 ],
			[ 1234567890, 987654321 ]
		]

		tiles = [
			[ -1, -1 ],
			[ 0, 0 ],
			[ 1227, 1227 ],
			[ 4822530, 3858024 ]
		]

		pixels.each_with_index do |px, i|
			assert_equal(from_pixel_to_tile(*px), tiles[i])
		end
	end

	def test_from_lng_lat_to_tile
		lng_lats = [
			[ 0, 0, 0 ],
			[ -45, 45, 1 ],
			[ -79.337, 43.729, 10 ]
		]
		tiles = [
			[ 0, 0 ],
			[ 0, 1 ],
			[ 286, 650 ]
		]

		lng_lats.each_with_index do |ll, i|
			assert_equal(from_lng_lat_to_tile(*ll), tiles[i])
		end
	end

	def test_from_lat_lng_to_tile
		lat_lngs = [
			[ 0, 0, 0 ],
			[ 45, -45, 1 ],
			[ 43.729, -79.337, 10 ]
		]
		tiles = [
			[ 0, 0 ],
			[ 0, 1 ],
			[ 286, 650 ]
		]

		lat_lngs.each_with_index do |ll, i|
			assert_equal(from_lat_lng_to_tile(*ll), tiles[i])
		end
	end

	def test_from_lng_lat_to_meters
		lng_lats = [
			[ 0, 0 ],
			[ -45, 45 ],
			[ -79.337, 43.729 ]
		]
		tiles = [
			[ 0.0, -7.08115455161362e-10 ],
			[ -5009377.08569731, 5621521.48619207 ],
			[ -8831754.44106595, 5423599.63984685 ]
		]

		lng_lats.each_with_index do |ll, i|
			from_lng_lat_to_meters(*ll).each_with_index do |j, ii|
				assert_in_delta(tiles[i][ii], j, 0.00001)
			end
		end
	end

	def test_from_lat_lng_to_meters
		lat_lngs = [
			[ 0, 0 ],
			[ 45, -45 ],
			[ 43.729, -79.337 ]
		]
		tiles = [
			[ 0.0, -7.08115455161362e-10 ],
			[ -5009377.08569731, 5621521.48619207 ],
			[ -8831754.44106595, 5423599.63984685 ]
		]

		lat_lngs.each_with_index do |ll, i|
			from_lat_lng_to_meters(*ll).each_with_index do |j, ii|
				assert_in_delta(tiles[i][ii], j, 0.00001)
			end
		end
	end

	def test_from_meters_to_lng_lat
		meters = [
			[ 0, 0 ],
			[ 12456789, 987654321 ],
			[ 602214179, 662606896 ]
		]

		lng_lats = [
			[ 0.0, 0.0 ],
			[ 90.0, 111.901239497519 ],
			[ 90.0, 5409.78201309189 ]
		]

		meters.each_with_index do |m, i|
			from_meters_to_lng_lat(*m).each_with_index do |j, ii|
				assert_in_delta(lng_lats[i][ii], j, 0.0000000001)
			end
		end
	end

	def test_from_meters_to_lat_lng; end

	def test_from_pixel_to_meters
		pixels = [
			[ 0, 0, 0 ],
			[ 1, 1, 10 ],
			[ 161803, 241421, 13 ]
		]

		meters = [
			[ -20037508.3427892, -20037508.3427892 ],
			[ -20037355.4687327, -20037355.4687327 ],
			[ -16945573.2208827, -15424132.3913804 ]
		]

		pixels.each_with_index do |px, i|
			from_pixel_to_meters(*px).each_with_index do |j, ii|
				assert_in_delta(meters[i][ii], j, 0.0000001)
			end
		end
	end

	def test_from_meters_to_pixel
		pixels = [
			[ 0, 0 ],
			[ 0, 0 ],
			[ 161802, 241420 ]
		]

		meters = [
			[ -20037508.3427892, -20037508.3427892, 0 ],
			[ -20037355.4687327, -20037355.4687327, 10 ],
			[ -16945573.2208827, -15424132.3913804, 13 ]
		]

		meters.each_with_index do |m, i|
			assert_equal(from_meters_to_pixel(*m), pixels[i])
		end
	end

	def test_from_meters_to_tile
		tiles = [
			[ 0, 0 ],
			[ 16, 15 ],
			[ 632, 943 ]
		]

		meters = [
			[ 0, 0, 0 ],
			[ 32768, -32768, 5 ],
			[ -16945573.2208827, -15424132.3913804, 13 ]
		]

		meters.each_with_index do |m, i|
			assert_equal(from_meters_to_tile(*m), tiles[i])
		end
	end

	def test_tile_meters_bounds
		tiles = [
			[ 0, 0, 0 ],
			[ 10, 10, 10 ],
			[ 21, 21, 21 ]
		]
		bounds = [
			[ -20037508.3427892, -20037508.3427892, 20037508.3427892, 20037508.3427892 ],
			[ -19646150.7579691, -19646150.7579691, -19607014.9994871, -19607014.9994871 ],
			[ -20037107.0483907, -20037107.0483907, -20037087.9391337, -20037087.9391337 ]
		]

		tiles.each_with_index do |t, i|
			tile_meters_bounds(*t).each_with_index do |j, ii|
				assert_in_delta(bounds[i][ii], j, 0.0000001)
			end
		end
	end

	def test_tile_lng_lat_bounds
		tiles = [
			[ 0, 0, 0 ],
			[ 10, 10, 10 ],
			[ 21, 21, 21 ]
		]
		bounds = [
			[ -85.0511287798066, -180.0, 85.0511287798066, 180.0 ],
			[ -84.7383871209534, -176.484375, -84.7060489350415, -176.1328125 ],
			[ -85.050817788051, -179.996395111084, -85.0508029784335, -179.996223449707 ]
		]

		tiles.each_with_index do |t, i|
			tile_lng_lat_bounds(*t).each_with_index do |j, ii|
				assert_in_delta(bounds[i][ii], j, 0.0000001)
			end
		end
	end

	def test_tile_lat_lng_bounds
		tiles = [
			[ 0, 0, 0 ],
			[ 10, 10, 10 ],
			[ 21, 21, 21 ]
		]
		bounds = [
			[ -180.0, -85.0511287798066, 180.0, 85.0511287798066 ],
			[ -176.484375, -84.7383871209534, -176.1328125, -84.7060489350415 ],
			[ -179.996395111084, -85.050817788051, -179.996223449707, -85.0508029784335 ]
		]

		tiles.each_with_index do |t, i|
			tile_lat_lng_bounds(*t).each_with_index do |j, ii|
				assert_in_delta(bounds[i][ii], j, 0.0000001)
			end
		end
	end

	def test_resolution
		zooms = [ 0, 2, 4, 8, 16, 32 ]
		resolutions = [
			156543.033928041,
			39135.7584820102,
			9783.93962050256,
			611.49622628141,
			2.38865713391176,
			3.64480153489953e-05
		]

		zooms.each_with_index do |z, i|
			assert_in_delta(resolution(z), resolutions[i], 0.000001)
		end
	end

	def test_minmax
		minmaxes = [
			[ 0, 1, 2 ],
			[ -2, 1, 0 ]
		]
		expected = [
			1,
			0
		]

		minmaxes.each_with_index do |m, i|
			assert_equal(minmax(*m), expected[i])
		end
	end
end
