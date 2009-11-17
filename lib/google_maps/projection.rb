
module GoogleMaps
	# Much of the code in this module is based on...
	#
	# * Google's own projection documentation:
	#   http://code.google.com/apis/maps/documentation/overlays.html#Projections
	# * a couple of articles by Charlie Savage:
	#   http://cfis.savagexi.com/2006/05/03/google-maps-deconstructed
	# * MapTiler, tile generator for Python:
	#   http://code.google.com/p/maptiler/
	module Projection
		DEG_TO_RAD = Math::PI / 180
		RAD_TO_DEG = 180 / Math::PI
		TILE_SIZE = 256.0
		ORIGIN_SHIFT = Math::PI * 6378137
		RESOLUTION = ORIGIN_SHIFT / TILE_SIZE * 2

		def self.included(base)
			base.send(:include, InstanceMethods)
		end

		module InstanceMethods
			def init_levels(levels = nil) #:nodoc:
				unless @bc
					levels ||= 22
					@bc = []
					@cc = []
					@zc = []
					@ac = []
					tile_size = TILE_SIZE

					levels.times do |d|
						e = tile_size / 2;
						@bc << tile_size / 360.0
						@cc << tile_size / (2 * Math::PI)
						@zc << [ e, e ]
						@ac << tile_size
						tile_size *= 2
					end
				end
			end

			# Converts from a Geos::Point or WKB in hex or binary to a reprojected
			# Geos::Point using Google Maps' Mercator projection.
			def from_geos_to_pixel(geom, zoom, levels = nil)
				init_levels(levels)

				geom = case geom
					when Geos::Geometry
						geom
					when /^[A-Fa-f0-9]+$/
						Geos::WkbReader.new.read_hex(geom)
					when String
						Geos::WkbReader.new.read(geom)
				end

				coord_seq = geom.centroid.coord_seq
				pixel = from_lng_lat_to_pixel(coord_seq.get_x(0), coord_seq.get_y(0), zoom)
				Geos::WktReader.new.read("POINT(#{pixel.join(' ')})")
			end

			# Converts from lng and lat values into Google Maps' Mercator
			# projection.
			def from_lng_lat_to_pixel(lng, lat, zoom, levels = nil)
				init_levels(levels)

				d = @zc[zoom]
				e = (d[0] + lng * @bc[zoom]).round
				f = minmax(Math.sin(DEG_TO_RAD * lat), -0.9999, 0.9999)
				g = (d[1] + 0.5 * Math.log((1 + f) / (1 - f)) * -@cc[zoom]).round
				[ e, g ]
			end

			# Converts from lat and lng values into Google Maps' Mercator
			# projection.
			def from_lat_lng_to_pixel(lat, lng, zoom, levels = nil)
				from_lng_lat_to_pixel(lng, lat, zoom, levels)
			end

			# Converts from Google Maps' Mercator pixel projection into
			# approximately WGS84 longlat. Note that you'll be losing some
			# precision during the conversion as pixels are rounded off into
			# integers.
			def from_pixel_to_lng_lat(x, y, zoom, levels = nil)
				init_levels(levels)

				e = @zc[zoom]
				f = (x - e[0]) / @bc[zoom]
				g = (y - e[1]) / -@cc[zoom]
				h = RAD_TO_DEG * (2 * Math.atan(Math.exp(g)) - 0.5 * Math::PI)
				[ f, h ]
			end

			# Same as from_pixel_to_lng_lat but with the return Array reversed
			# to lat/lng.
			def from_pixel_to_lat_lng(x, y, zoom, levels = nil)
				from_pixel_to_lng_lat(x, y, zoom, levels).reverse
			end

			# Converts from pixels to tile coordinates.
			def from_pixel_to_tile(x, y)
				[
					((x / TILE_SIZE).ceil - 1),
					((y / TILE_SIZE).ceil - 1)
				]
			end

			# Converts from lng/lat directly to tile coordinates for a given
			# zoom level.
			def from_lng_lat_to_tile(lng, lat, zoom)
				from_meters_to_tile(*(from_lng_lat_to_meters(lng, lat) << zoom))
			end

			# Same as from_lng_lat_to_tile but with the input coordinates
			# reversed. The output is still in [ x, y ].
			def from_lat_lng_to_tile(lat, lng, zoom)
				from_lng_lat_to_tile(lng, lat, zoom)
			end

			# Converts from lng/lat to meters.
			def from_lng_lat_to_meters(lng, lat)
				x = lng * ORIGIN_SHIFT / 180.0
				y = 	Math.log(Math.tan((90 + lat) * Math::PI / 360.0)) /
					(Math::PI / 180.0) *
					(ORIGIN_SHIFT / 180.0)
				[ x, y ]
			end

			# Same as from_lng_lat_to_meters but with the input coordinates
			# reversed. The output is still in [ x, y ].
			def from_lat_lng_to_meters(lat, lng)
				from_lng_lat_to_meters(lng, lat)
			end

			# Converts from meters to lng/lat.
			def from_meters_to_lng_lat(x, y)
				lng = (x / ORIGIN_SHIFT) * 180.0
				lat = (180.0 / Math::PI) *
					(2 * Math.atan(Math.exp(
						((y / ORIGIN_SHIFT) * 180.0) * Math::PI / 180.0)
					) - (Math::PI / 2.0))
				[ lat, lng ]
			end

			# Same as from_meters_to_lng_lat but with the output coordinates
			# reversed.
			def from_meters_to_lat_lng(x, y)
				from_meters_to_lng_lat(x, y).reverse
			end

			# Converts from a pixel in Google's mercator projection for a
			# particular zoom level to meters.
			def from_pixel_to_meters(x, y, zoom)
				res = resolution(zoom)
				[
					x * res - ORIGIN_SHIFT,
					y * res - ORIGIN_SHIFT
				]
			end

			# Converts from meters to a pixel in Google's mercator projection
			# for a particular zoom level.
			def from_meters_to_pixel(x, y, zoom)
				res = resolution(zoom)
				[
					((x + ORIGIN_SHIFT) / res).to_i,
					((y + ORIGIN_SHIFT) / res).to_i
				]
			end

			# Converts from meters to a tile.
			def from_meters_to_tile(x, y, zoom)
				from_pixel_to_tile(*from_meters_to_pixel(x, y, zoom))
			end

			# Returns a tile's bounding box in meters in the form
			# [ min_x, min_y, max_x, max_y ].
			def tile_meters_bounds(x, y, zoom)
				min_x, min_y = from_pixel_to_meters(x * TILE_SIZE, y * TILE_SIZE, zoom)
				max_x, max_y = from_pixel_to_meters((x + 1) * TILE_SIZE, (y + 1) * TILE_SIZE, zoom)
				[ min_x, min_y, max_x, max_y ]
			end

			# Returns a tile's bounding box in lng/lat in the form
			# [ min_lng, min_lat, max_lng, max_lat ], i.e. SW/NE pairs.
			def tile_lng_lat_bounds(x, y, zoom)
				bounds = tile_meters_bounds(x, y, zoom)
				min_lng, min_lat = from_meters_to_lng_lat(bounds[0], bounds[1])
				max_lng, max_lat = from_meters_to_lng_lat(bounds[2], bounds[3])

				[ min_lng, min_lat, max_lng, max_lat ]
			end

			# Returns a tile's bounding box in lng/lat in the form
			# [ min_lat, min_lng, max_lat, max_lng ], i.e. SW/NE pairs.
			def tile_lat_lng_bounds(x, y, zoom)
				bounds = tile_lng_lat_bounds(x, y, zoom)
				[ bounds[1], bounds[0], bounds[3], bounds[2] ]
			end

			# Returns the pixel resolution of a zoom level.
			def resolution(zoom)
				RESOLUTION / (2 ** zoom)
			end

			def minmax(a, b, c) #:nodoc:
				[ [ a, b ].max, c ].min
			end
		end

		self.extend InstanceMethods
	end
end
