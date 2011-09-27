
module GoogleMapsTools
	GOOGLE_MAPS_TOOLS_BASE = File.join(File.dirname(__FILE__))

	autoload :Constants,
		File.join(GOOGLE_MAPS_TOOLS_BASE, %w{ google_maps_tools constants })
	autoload :MarkerClusterer,
		File.join(GOOGLE_MAPS_TOOLS_BASE, %w{ google_maps_tools marker_clusterer })
	autoload :PolylineEncoder,
		File.join(GOOGLE_MAPS_TOOLS_BASE, %w{ google_maps_tools polyline_encoder })
	autoload :Projection,
		File.join(GOOGLE_MAPS_TOOLS_BASE, %w{ google_maps_tools projection })
	autoload :QuadTree,
		File.join(GOOGLE_MAPS_TOOLS_BASE, %w{ google_maps_tools quad_tree })
end

