
module GoogleMaps
	# An implementation of a quad tree for clustering points on a Google Map.
	# (Or for that matter, any sort of slippy map that uses Google's projection,
	# a.k.a. EPSG:900913, a.k.a. EPSG:3857, a.k.a. EPSG:3785.)
	#
	# Microsoft's Bing maps documentation has some good information on how
	# the quad ree's "quad keys" are structured:
	#
	# http://msdn.microsoft.com/en-us/library/bb259689.aspx
	#
	# As does MapTiler:
	#
	# http://www.maptiler.org/google-maps-coordinates-tile-bounds-projection/
	module QuadTree
		ORIGIN_SHIFT = 2 * Math::PI * 6378137 / 2.0

		def self.included(base)
			base.send(:include, InstanceMethods)
		end

		module InstanceMethods
			include GoogleMaps::Projection

			# Creates a quad tree key based on tiles and the zoom level.
			def quad_tree(tx, ty, zoom)
				quad_key = ''
				ty = (2 ** zoom - 1) - ty
				zoom.downto(1) do |i|
					digit = 0
					mask = 1 << (i - 1)
					digit += 1 if (tx & mask) != 0
					digit += 2 if (ty & mask) != 0
					quad_key << digit.to_s
				end
				quad_key
			end

			# Converts from a quad_tree to tile coordinates for a particular
			# zoom level.
			def from_quad_tree_to_tile(qt, zoom)
				tx = 0
				ty = 0

				qt = "0#{qt}" if qt[0] != ?0

				zoom.downto(1) do |i|
					ch = qt[zoom - i].chr
					mask = 1 << (i - 1)
					digit = ch.to_i

					tx += mask if digit & 1 > 0
					ty += mask if digit & 2 > 0
				end
				ty = ((1 << zoom) - 1) - ty
				[ tx, ty ]
			end

			# Converts from lng/lat to a quad tree.
			def from_lng_lat_to_quad_tree(lng, lat, zoom)
				mx, my = from_lng_lat_to_meters(lng, lat)
				tx, ty = from_meters_to_tile(mx, my, zoom)
				quad_tree(tx, ty, zoom)
			end

			# Same as from_lng_lat_to_quad_tree but with the coordinates in
			# lat/lng.
			def from_lat_lng_to_quad_tree(lat, lng, zoom)
				from_lng_lat_to_quad_tree(lng, lat, zoom)
			end

			# Returns the lng/lat bounds for the quad tree in the form of
			# [ min_lng, min_lat, max_lng, max_lat ], i.e. SW/NE pairs.
			def from_quad_tree_to_lng_lat_bounds(qt)
				zoom = qt.length
				tx, ty = from_quad_tree_to_tile(qt, zoom)
				tile_lng_lat_bounds(tx, ty, zoom)
			end

			# Same as from_quad_tree_to_lng_lat_bounds but with the returned
			# Array in the form of [ min_lat, min_lng, max_lat, max_lng ].
			def from_quad_tree_to_lat_lng_bounds(qt)
				bounds = from_quad_tree_to_lng_lat_bounds(qt)
				[ bounds[1], bounds[0], bounds[3], bounds[2] ]
			end

			# Creates a quad tree key using a Geos object. The geom can be
			# passed as a Geos::Geometry object, a String in WKB in either hex
			# or binary, or a String in WKT. When the geom is anything other
			# than a POINT, we use the geometry's centroid to create the quad
			# tree.
			def from_geos_to_quad_tree(geom, zoom)
				geom = case geom
					when Geos::Geometry
						geom
					when /^[A-Fa-f0-9]+$/
						Geos::WkbReader.new.read_hex(geom)
					when /^[PLMCG]/
						Geos::WktReader.new.read(geom)
					when String
						Geos::WkbReader.new.read(geom)
				end

				coord_seq = geom.centroid.coord_seq
				from_lng_lat_to_quad_tree(coord_seq.get_x(0), coord_seq.get_y(0), zoom)
			end
		end

		self.extend InstanceMethods
	end
end
