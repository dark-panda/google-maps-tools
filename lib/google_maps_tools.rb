
module GoogleMapsTools
  GOOGLE_MAPS_TOOLS_BASE = File.join(File.dirname(__FILE__))

  autoload :Constants,
    File.join(GOOGLE_MAPS_TOOLS_BASE, %w{ google_maps_tools constants })
  autoload :GeocoderResponse,
    File.join(GOOGLE_MAPS_TOOLS_BASE, %w{ google_maps_tools geocoder_response })
  autoload :MarkerClusterer,
    File.join(GOOGLE_MAPS_TOOLS_BASE, %w{ google_maps_tools marker_clusterer })
  autoload :PolylineEncoder,
    File.join(GOOGLE_MAPS_TOOLS_BASE, %w{ google_maps_tools polyline_encoder })
  autoload :Projection,
    File.join(GOOGLE_MAPS_TOOLS_BASE, %w{ google_maps_tools projection })
  autoload :QuadTree,
    File.join(GOOGLE_MAPS_TOOLS_BASE, %w{ google_maps_tools quad_tree })
  autoload :UrlSigner,
    File.join(GOOGLE_MAPS_TOOLS_BASE, %w{ google_maps_tools url_signer })
end

