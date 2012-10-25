module Mixpanel::Person
  PERSON_PROPERTIES = %w{email created first_name last_name name last_login username country_code}
  PERSON_URL = 'http://api.mixpanel.com/engage/'
  
  def set(distinct_id, properties={}, options={})
    engage :set, distinct_id, properties, options
  end
  
  def increment(distinct_id, properties={}, options={})
    engage :add, distinct_id, properties, options
  end
  
  def append_set(properties={})
    append 'people.set', properties_hash(properties, PERSON_PROPERTIES)
  end
  
  def append_increment(property, increment=1)
    append 'people.increment', property, increment
  end
  
  def append_register(properties={})
    append 'register', properties_hash(properties, PERSON_PROPERTIES)
  end
  
  def append_identify(distinct_id)
    append 'identify', distinct_id
  end
  
  protected
  
  def engage(action, distinct_id, properties, options)
    options.reverse_merge! :async => @async, :url => PERSON_URL
    data = build_person action, distinct_id, properties
    url = "#{options[:url]}?data=#{encoded_data(data)}"
    parse_response request(url, options[:async])
  end
  
  def build_person(action, distinct_id, properties)
    { "$#{action}".to_sym => properties_hash(properties, PERSON_PROPERTIES), :$token => @token, :$distinct_id => distinct_id }
  end
end