
module GoogleMaps
	module Constants
		# http://code.google.com/apis/maps/documentation/reference.html#GGeoAddressAccuracy
		GEO_ADDRESS_ACCURACY = {
			# (Since 2.59)
			:unknown_location => 0,

			# Country level accuracy.
			:country => 1,

			# Region (state, province, prefecture, etc.) level accuracy.
			:region => 2,

			# Sub-region (county, municipality, etc.) level accuracy.
			:sub_region => 3,

			# Town (city, village) level accuracy.
			:city => 4,

			# Post code (zip code) level accuracy.
			:postal_code => 5,

			# Street level accuracy.
			:street_level => 6,

			# Intersection level accuracy.
			:intersection => 7,

			# Address level accuracy.
			:address => 8,

			# Premise (building name, property name, shopping center, etc.)
			# level accuracy.
			:premise => 9
		}.freeze

		# http://code.google.com/apis/maps/documentation/reference.html#GGeoStatusCode
		GEO_STATUS_CODES = {
			:success             => 200,
			:bad_request         => 400,
			:server_error        => 500,
			:missing_query       => 601,
			:missing_address     => 602,
			:unknown_address     => 602,
			:unavailable_address => 603,
			:unknown_directions  => 604,
			:bad_key             => 610,
			:too_many_queries    => 620
		}.freeze
	end
end
