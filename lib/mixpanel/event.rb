module Event
  EVENT_PROPERTIES = %w{initial_referrer initial_referring_domain search_engine os browser referrer referring_domain}
  TRACK_URL = 'http://api.mixpanel.com/track/'
  IMPORT_URL = 'http://api.mixpanel.com/import/'
  
  def track event, properties={}, env={}, options={}
    options.reverse_merge! :async => @async, :url => TRACK_URL
    data = build_event event, properties, env
    url = "#{options[:url]}?data=#{encoded_data(data)}"
    parse_response request(url, options[:async])
  end
  
  def import api_key, event, properties={}, env={}, options={}
    options.reverse_merge! :async => @async, :url => IMPORT_URL
    data = build_event event, properties, env
    url = "#{options[:url]}?data=#{encoded_data(data)}&api_key=#{api_key}"
    parse_response request(url, options[:async])
  end
  
  protected
  
  def ip env
    (env['HTTP_X_FORWARDED_FOR'] || env['REMOTE_ADDR'] || '').split(',').last
  end
  
  def build_event event, properties, env
    properties.reverse_merge! :time => Time.now, :ip => ip(env), :token => @token
    { :event => event, :properties => properties_hash(properties, EVENT_PROPERTIES) }
  end
end