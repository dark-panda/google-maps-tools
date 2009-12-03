
module GoogleMaps
	class QuadTreeFieldNotFound < Exception
		def initialize(marker)
			super("Couldn't find quad tree field for marker #{marker.inspect}")
		end
	end

	class BadZoomLevel < ArgumentError
		def initialize(zoom)
			super("Bad zoom level for #{zoom}")
		end
	end

	class MarkerClusterer
		attr_reader :total_points

		def initialize(*args)
			raise ArgumentError.new unless args.length.between?(0, 3)

			@clusters = Hash.new
			@total_points = 0

			if args.length > 0
				add_markers(*args)
			end
		end

		def <<(*args)
			add_markers(*args)
		end
		alias :push :<<

		def clusters
			@clusters_cache ||= @clusters.select { |k, v| v.length > 1 }
		end

		def singles
			@singles_cache ||= @clusters.select { |k, v| v.length <= 1 }
		end

		private
			def add_markers(*args)
				raise ArgumentError.new("wrong number of arguments (#{args.length}) for 1") unless
					args.length.between?(1, 3)

				options = {
					:quad_tree_field => 'quad_tree'
				}.merge(args.last.is_a?(Hash) ? args.pop : {})

				markers, zoom = nil

				if args.length > 0
					zoom = if args.last.is_a?(Numeric)
						args.pop
					end

					markers = if args.length == 1
						args.pop
					end
				end

				zoom_range = 0..(zoom || -1)

				markers.each do |marker|
					quad_tree = if options[:quad_tree_field].is_a?(Proc)
						options[:quad_tree_field].call(marker)[zoom_range]
					elsif marker.respond_to?(options[:quad_tree_field])
						marker.send(options[:quad_tree_field])[zoom_range]
					elsif marker.respond_to?(:[])
						marker[options[:quad_tree_field]][zoom_range]
					else
						raise QuadTreeFieldNotFound.new(marker)
					end
					@clusters[quad_tree] ||= Array.new
					@clusters[quad_tree] << marker
					@total_points += 1
				end
			ensure
				clear_cache
			end

			def clear_cache
				@clusters_cache = nil
				@singles_cache = nil
			end
	end
end
