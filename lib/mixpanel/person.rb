module Mixpanel::Person
  PERSON_PROPERTIES = %w{email created first_name last_name name last_login username country_code}
  PERSON_REQUEST_PROPERTIES = %w{token distinct_id ip}
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

  def append_people_identify(distinct_id)
    append 'people.identify', distinct_id
  end

  protected

  def engage(action, request_properties_or_distinct_id, properties, options)
    default = {:async => @async, :url => PERSON_URL}
    options = default.merge(options)

    request_properties = person_request_properties(request_properties_or_distinct_id)

    data = build_person action, request_properties, properties
    url = "#{options[:url]}?data=#{encoded_data(data)}"
    parse_response request(url, options[:async])
  end

  def person_request_properties(request_properties_or_distinct_id)
    default = {:token => @token, :ip => ip}
    if request_properties_or_distinct_id.respond_to? :to_hash
      default.merge(request_properties_or_distinct_id)
    else
      default.merge({ :distinct_id => request_properties_or_distinct_id })
    end
  end

  def build_person(action, request_properties, person_properties)
    properties_hash(request_properties, PERSON_REQUEST_PROPERTIES).merge({ "$#{action}".to_sym => properties_hash(person_properties, PERSON_PROPERTIES) })
  end
end
