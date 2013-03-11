# encoding: UTF-8

class GoogleMapsTools::GeocoderResponse
  attr_reader :geocode, :results, :status

  HASH_AUTOVIVIFIER = proc { |h, k| h[k] = Hash.new(&HASH_AUTOVIVIFIER) }

  def initialize(json_or_hash, options = {})
    @cache = Hash.new(&HASH_AUTOVIVIFIER)

    geocode = case json_or_hash
      when String
        JSON.load(json_or_hash)
      when Hash
        json_or_hash
      else
        raise ArgumentError.new("Expected a String or Hash")
    end

    @geocode = if geocode['results'].is_a?(Array)
      geocode
    elsif geocode['address_components'].is_a?(Array)
      {
        'results' => [
          geocode
        ],
        'status' => 'OK'
      }
    else
      raise ArgumentError.new("Couldn't parse JSON into GoogleMapsGeocde")
    end

    @results = @geocode['results']
    @status = @geocode['status']
  end

  def build_name(components, idx = 0)
    return if self.geocode['status'] != 'OK'
    return unless data_present?(components)

    ret = components.inject([]) { |memo, value|
      self.component_injector(memo, value, idx)
    }.compact

    ret.join(', ') if data_present?(ret)
  end

  def short_components(*args)
    return if self.geocode['status'] != 'OK'

    options = {
      :index => 0
    }.merge(args.extract_options!)

    components = args.collect(&:to_s)
    idx = options[:index]

    self.geocode['results'][idx]['address_components'].inject(HashWithIndifferentAccess.new) do |memo, c|
      memo.tap {
        if components.blank? || components.include?(c['types'][0])
          memo[c['types'][0]] = c['short_name']
        end
      }
    end
  end

  def long_components(*args)
    return if self.geocode['status'] != 'OK'

    options = {
      :index => 0
    }.merge(args.extract_options!)

    components = args.collect(&:to_s)
    idx = options[:index]

    self.geocode['results'][idx]['address_components'].inject(HashWithIndifferentAccess.new) do |memo, c|
      memo.tap {
        if components.blank? || components.include?(c['types'][0])
          memo[c['types'][0]] = c['long_name']
        end
      }
    end
  end

  def short_name(idx = 0)
    return if self.geocode['status'] != 'OK'

    check_bounds(idx)

    if @cache['short_names'].has_key?(idx)
      @cache['short_names'][idx]
    else
      @cache['short_names'][idx] = self.build_name([
        [
          [ 'establishment' ],
          [ 'colloquial_area' ],
          [ 'neighborhood' ],
          [ 'sublocality' ],
          [ 'locality' ],
          [ 'administrative_area_level_3' ],
          [ 'administrative_area_level_2' ],
          [ 'administrative_area_level_1' ]
        ]
      ], idx)
    end
  end

  def long_name(idx = 0)
    return if self.geocode['status'] != 'OK'

    check_bounds(idx)

    if @cache['long_names'].has_key?(idx)
      @cache['long_names'][idx]
    else
      # Special case where we're dealing with an entire province or state.
      if self.geocode['results'][idx]['types'].sort == %w{ administrative_area_level_1 political }
        @cache['long_names'][idx] = self.build_name([
          [ 'administrative_area_level_1' ]
        ], idx)
      else
        @cache['long_names'][idx] = self.build_name([
          [
            [ 'establishment', 'long_name' ],
            [ 'neighborhood', 'long_name' ],
            [ 'colloquial_area', 'long_name' ]
          ],
          [
            [ 'sublocality', 'long_name' ],
            [ 'locality', 'long_name' ],
            [ 'administrative_area_level_3', 'long_name' ],
            [ 'administrative_area_level_2', 'long_name' ],
          ],
          [ 'administrative_area_level_1', 'short_name' ]
        ], idx)
      end
    end
  end

  def place_name(short_or_long = :long, idx = 0)
    return if self.geocode['status'] != 'OK'
    check_bounds(idx)

    short_or_long = "#{short_or_long}_name"

    if @cache['place_names'][short_or_long].has_key?(idx)
      @cache['place_names'][short_or_long][idx]
    else
      @cache['place_names'][short_or_long][idx] = self.build_name([[
        [ 'establishment', short_or_long ],
        [ 'neighborhood', short_or_long ],
        [ 'colloquial_area', short_or_long ]
      ]])
    end
  end

  def city(short_or_long = :long, idx = 0)
    return if self.geocode['status'] != 'OK'
    check_bounds(idx)

    short_or_long = "#{short_or_long}_name"

    if @cache['cities'][short_or_long].has_key?(idx)
      @cache['cities'][short_or_long][idx]
    else
      @cache['cities'][short_or_long][idx] = self.build_name([[
        [ 'sublocality', short_or_long ],
        [ 'locality', short_or_long ],
        [ 'administrative_area_level_3', short_or_long ],
        [ 'administrative_area_level_2', short_or_long ]
      ]])
    end
  end

  def province(short_or_long = :long, idx = 0)
    return if self.geocode['status'] != 'OK'
    check_bounds(idx)

    short_or_long = "#{short_or_long}_name"

    if @cache['provinces'][short_or_long].has_key?(idx)
      @cache['provinces'][short_or_long][idx]
    else
      @cache['provinces'][short_or_long][idx] = self.component_finder('administrative_area_level_1', idx, short_or_long)
    end
  end

  def country(short_or_long = :long, idx = 0)
    return if self.geocode['status'] != 'OK'
    check_bounds(idx)

    short_or_long = "#{short_or_long}_name"

    if @cache['countries'][short_or_long].has_key?(idx)
      @cache['countries'][short_or_long][idx]
    else
      @cache['countries'][short_or_long][idx] = self.component_finder('country', idx, short_or_long)
    end
  end

  def formatted_address(idx = 0)
    return if self.geocode['status'] != 'OK'

    check_bounds(idx)

    self.geocode['results'][idx]['formatted_address']
  end

  def the_geom(idx = 0)
    return if self.geocode['status'] != 'OK'

    check_bounds(idx)

    if @cache[:the_geoms].has_key?(idx)
      @cache[:the_geoms][idx]
    else
      geom = traverse(self.geocode['results'][idx], 'geometry', 'location')

      @cache[:the_geoms][idx] = if geom.is_a?(Hash)
        Geos.read(geom.values_at('lat', 'lng').join(', '))
      else
        Geos.read(geom)
      end
    end
  end

  def the_bounds(idx = 0)
    return if self.geocode['status'] != 'OK'

    check_bounds(idx)

    if @cache[:the_bounds].has_key?(idx)
      @cache[:the_bounds][idx]
    else
      bounds = traverse(self.geocode['results'][idx], 'geometry', 'bounds') ||
        traverse(self.geocode['results'][idx], 'geometry', 'viewport')

      @cache[:the_bounds][idx] = if bounds.is_a?(Hash)
        begin
          sw = traverse(bounds, 'southwest', :nil => {}).values_at('lng', 'lat').join(' ')
          ne = traverse(bounds, 'northeast', :nil => {}).values_at('lng', 'lat').join(' ')
          Geos.read("MULTIPOINT(#{sw}, #{ne})").envelope
        rescue
        end
      else
        Geos.read(bounds)
      end
    end
  end

  def types(idx = 0)
    return if  self.geocode['status'] != 'OK'

    check_bounds(idx)

    self.geocode['results'][idx]['types'].sort
  end

  def [](idx)
    return if self.geocode['status'] != 'OK'

    check_bounds(idx)

    self.geocode['results'][idx]
  end

  def as_json(*args)
    self.geocode
  end

  protected
    def component_finder(component, idx = 0, long_or_short = 'long_name')
      component = component.to_s
      long_or_short = if long_or_short
        long_or_short.to_s
      else
        'long_name'
      end

      components = self.geocode['results'][idx]['address_components'].detect { |a|
        a['types'].include?(component)
      }

      components[long_or_short] if components
    end

    def component_injector(memo, value, idx)
      memo.tap {
        if value.first.is_a?(Array)
          value.each do |vv|
            l = memo.length
            r = self.component_injector(memo, vv, idx)
            break if l < memo.length
          end
        else
          if r = self.component_finder(value[0], idx, value[1])
            memo << r
          end
        end
      }
    end

    def check_bounds(idx)
      if idx >= self.geocode['results'].length || idx < 0
        raise ArgumentError.new("Index out of bounds")
      end
    end

    def data_present?(what)
      if what.respond_to?(:empty?)
        !what.empty?
      else
        !!what
      end
    end

    def traverse(what, *args)
      options = if args.last.is_a?(Hash)
        args.pop
      else
        {}
      end

      ret = args.inject(what) do |memo, obj|
        if memo.respond_to?(:[])
          memo[obj] || break
        else
          memo
        end
      end

      if options[:nil] && ret.nil?
        options[:nil]
      else
        ret
      end
    end
end

