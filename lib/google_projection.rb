
module GoogleProjection
	DEG_TO_RAD = Math::PI / 180
	RAD_TO_DEG = 180 / Math::PI

	def self.included(base)
		base.send(:include, InstanceMethods)
	end

	module InstanceMethods
		def init_levels(levels = nil)
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

		def from_geometry_to_pixels(wkb, zoom, levels = nil)
			init_levels(levels)

			geom = Geos::WkbReader.new.read_hex(wkb).coord_seq
			pixels = from_lng_lat_to_pixels(geom.get_x(0), geom.get_y(0), zoom)
			Geos::WkbWriter.new.write_hex(
				Geos::WktReader.new.read("POINT(#{pixels.join(' ')})")
			)
		end

		def from_lng_lat_to_pixels(lng, lat, zoom, levels = nil)
			init_levels(levels)

			d = @zc[zoom]
			e = (d[0] + lng * @bc[zoom]).round
			f = minmax(Math.sin(DEG_TO_RAD * lat), -0.9999, 0.9999)
			g = (d[1] + 0.5 * Math.log((1 + f) / (1 - f)) * -@cc[zoom]).round
			return [ e, g ]
		end

		def from_lat_lng_to_pixels(lat, lng, zoom, levels = nil)
			init_levels(levels)

			from_lng_lat_to_pixels(lng, lat, zoom, levels = nil)
		end

		def from_pixels_to_lng_lat(x, y, zoom, levels = nil)
			init_levels(levels)

			e = @zc[zoom]
			f = (x - e[0]) / @bc[zoom]
			g = (y - e[1]) / -@cc[zoom]
			h = RAD_TO_DEG * (2 * Math.atan(Math.exp(g)) - 0.5 * Math::PI)
			return [ f, h ]
		end

		def from_pixels_to_lat_lng(x, y, zoom, levels = nil)
			init_levels(levels)

			from_pixels_to_lng_lat(x, y, zoom).reverse
		end

		protected
			def minmax(a, b, c)
				[ [ a, b ].max, c ].min
			end
	end

	self.extend InstanceMethods
end
