
module GoogleProjection
	DEG_TO_RAD = Math::PI / 180
	RAD_TO_DEG = 180 / Math::PI

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
				tile_size = 256

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
		def from_geos_to_pixels(geom, zoom, levels = nil)
			init_levels(levels)

			geom = case geom
				when Geos::Point
					geom
				when /^[A-Fa-f0-9]+$/
					Geos::WkbReader.new.read_hex(geom)
				when String
					Geos::WkbReader.new.read(geom)
			end

			coord_seq = geom.coord_seq
			pixels = from_lng_lat_to_pixels(coord_seq.get_x(0), coord_seq.get_y(0), zoom)
			Geos::WktReader.new.read("POINT(#{pixels.join(' ')})")
		end

		# Converts from lng and lat values into Google Maps' Mercator
		# projection.
		def from_lng_lat_to_pixels(lng, lat, zoom, levels = nil)
			init_levels(levels)

			d = @zc[zoom]
			e = (d[0] + lng * @bc[zoom]).round
			f = minmax(Math.sin(DEG_TO_RAD * lat), -0.9999, 0.9999)
			g = (d[1] + 0.5 * Math.log((1 + f) / (1 - f)) * -@cc[zoom]).round
			return [ e, g ]
		end

		# Converts from lat and lng values into Google Maps' Mercator
		# projection.
		def from_lat_lng_to_pixels(lat, lng, zoom, levels = nil)
			from_lng_lat_to_pixels(lng, lat, zoom, levels)
		end

		# Converts from Google Maps' Mercator pixel projection into
		# approximately WGS84 longlat. Note that you'll be losing some
		# precision during the conversion as pixels are rounded off into
		# integers.
		def from_pixels_to_lng_lat(x, y, zoom, levels = nil)
			init_levels(levels)

			e = @zc[zoom]
			f = (x - e[0]) / @bc[zoom]
			g = (y - e[1]) / -@cc[zoom]
			h = RAD_TO_DEG * (2 * Math.atan(Math.exp(g)) - 0.5 * Math::PI)
			return [ f, h ]
		end

		# Same as from_pixels_to_lng_lat but with the return Array reversed
		# to latlong.
		def from_pixels_to_lat_lng(x, y, zoom, levels = nil)
			from_pixels_to_lng_lat(x, y, zoom, levels).reverse
		end

		# Converts from pixels to tile coordinates.
		def from_pixels_to_tile(x, y, zoom, levels = nil)
			[ (x / 256.0).floor, (y / 256.0).floor ]
		end

		protected
			def minmax(a, b, c) #:nodoc:
				[ [ a, b ].max, c ].min
			end
	end

	self.extend InstanceMethods
end
