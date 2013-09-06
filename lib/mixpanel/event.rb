module Mixpanel::Event
  EVENT_PROPERTIES = %w{initial_referrer initial_referring_domain search_engine os browser referrer referring_domain}
  TRACK_URL = 'http://api.mixpanel.com/track/'
  IMPORT_URL = 'http://api.mixpanel.com/import/'

  def track(event, properties={}, options={})
    track_event event, properties, options, TRACK_URL
  end

  def tracking_pixel(event, properties={}, options={})
    build_url event, properties, options.merge(:url => TRACK_URL, :img => true)
  end

  def redirect_url(event, redirect, properties={}, options={})
    build_url event, properties, options.merge(:url => TRACK_URL, :redirect => CGI::escape(redirect))
  end

  def import(event, properties={}, options={})
    track_event event, properties, options, IMPORT_URL
  end

  def append_track(event, properties={})
    append 'track', event, track_properties(properties, false)
  end

  def alias(name, properties={}, options={})
    track_event '$create_alias', properties.merge(:alias => name), options, TRACK_URL
  end

  def append_alias(aliased_id)
    append 'alias', aliased_id
  end

  protected

  def track_event(event, properties, options, default_url)
    default = {:url => default_url, :async => @async, :api_key => @api_key}
    options = default.merge(options)
    data = build_data(event, properties, options)
    parse_response post_request(options[:url], data, options[:async])
  end

  def track_properties(properties, include_token=true)
    default = {:time => Time.now, :ip => ip}
    properties = default.merge(properties)

    properties.merge!(:token => @token) if include_token
    properties_hash(properties, EVENT_PROPERTIES)
  end

  def build_event(event, properties)
    { :event => event, :properties => properties_hash(properties, EVENT_PROPERTIES) }
  end

  def build_data event, properties, options
    params = {}
    data = build_event event, track_properties(properties)
    params[:data] = encoded_data(data)
    params[:api_key] = options[:api_key] if options.fetch(:api_key, nil)
    params[:img] = 1 if options[:img]
    params[:test] = 1 if options[:test]
    params
  end

  def build_url event, properties, options
    data = build_event event, track_properties(properties)
    url = "#{options[:url]}?data=#{encoded_data(data)}"
    url << "&api_key=#{options[:api_key]}" if options.fetch(:api_key, nil)
    url << "&img=1" if options[:img]
    url << "&test=1" if options[:test]
    url << "&redirect=#{options[:redirect]}" if options[:redirect]
    url
  end
end
