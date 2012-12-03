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

  def import(event, properties={}, options={})
    track_event event, properties, options, IMPORT_URL
  end

  def append_track(event, properties={})
    append 'track', event, track_properties(properties, false)
  end

  protected

  def track_event(event, properties, options, default_url)
    options.reverse_merge! :url => default_url, :async => @async, :api_key => @api_key
    url = build_url event, properties, options
    parse_response request(url, options[:async])
  end

  def ip
    (@env['HTTP_X_FORWARDED_FOR'] || @env['REMOTE_ADDR'] || '').split(',').last
  end

  def track_properties(properties, include_token=true)
    properties.reverse_merge! :time => Time.now, :ip => ip
    properties.reverse_merge! :token => @token if include_token
    properties_hash properties, EVENT_PROPERTIES
  end

  def build_event(event, properties)
    { :event => event, :properties => properties_hash(properties, EVENT_PROPERTIES) }
  end

  def build_url event, properties, options
    data = build_event event, track_properties(properties)
    url = "#{options[:url]}?data=#{encoded_data(data)}"
    url << "&api_key=#{options[:api_key]}" if options[:api_key].present?
    url << "&img=1" if options[:img]
    url
  end
end
