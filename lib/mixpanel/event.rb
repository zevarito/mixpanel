module Event
  EVENT_PROPERTIES = %w{initial_referrer initial_referring_domain search_engine os browser referrer referring_domain}
  TRACK_URL = 'http://api.mixpanel.com/track/'
  IMPORT_URL = 'http://api.mixpanel.com/import/'
  
  def track event, properties={}, options={}
    options.reverse_merge! :async => @async, :url => TRACK_URL
    data = build_event event, track_properties(properties)
    url = "#{options[:url]}?data=#{encoded_data(data)}"
    parse_response request(url, options[:async])
  end
  
  def append_track event, properties={}
    properties = track_properties properties, false
    append 'track', event, properties
  end
  
  def import api_key, event, properties={}, options={}
    options.reverse_merge! :async => @async, :url => IMPORT_URL
    data = build_event event, track_properties(properties)
    url = "#{options[:url]}?data=#{encoded_data(data)}&api_key=#{api_key}"
    parse_response request(url, options[:async])
  end
  
  protected
  
  def ip
    (@env['HTTP_X_FORWARDED_FOR'] || @env['REMOTE_ADDR'] || '').split(',').last
  end
  
  def track_properties properties, include_token=true
    properties.reverse_merge! :time => Time.now, :ip => ip
    properties.reverse_merge! :token => @token if include_token
    properties_hash properties, EVENT_PROPERTIES
  end
  
  def build_event event, properties
    properties.reverse_merge! :time => Time.now, :ip => ip, :token => @token
    { :event => event, :properties => properties_hash(properties, EVENT_PROPERTIES) }
  end
end