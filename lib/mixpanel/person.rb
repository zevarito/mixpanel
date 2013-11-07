module Mixpanel::Person
  #from https://mixpanel.com/docs/people-analytics/special-properties
  PERSON_PROPERTIES = %w{email created first_name last_name name last_login username country_code region city}
  #from https://mixpanel.com/docs/people-analytics/people-http-specification-insert-data
  PERSON_REQUEST_PROPERTIES = %w{token distinct_id ip ignore_time}
  PERSON_URL = 'http://api.mixpanel.com/engage/'

  def set(distinct_id, properties={}, options={})
    engage :set, distinct_id, properties, options
  end

  def unset(distinct_id, property, options={})
    engage :unset, distinct_id, property, options
  end

  def set_once(distinct_id, properties={}, options={})
    engage :set_once, distinct_id, properties, options
  end

  def increment(distinct_id, properties={}, options={})
    engage :add, distinct_id, properties, options
  end

  def track_charge(distinct_id, amount, time=Time.now, options={})
    charge_properties = {
      '$transactions' => {
        '$amount' => amount,
        '$time' => time,
        }
      }
    engage :append, distinct_id, charge_properties, options
  end

  def delete(distinct_id)
    engage 'delete', distinct_id, {}, {}
  end

  def reset_charges(distinct_id, options={})
    engage :set, distinct_id, { '$transactions' => [] }, options
  end

  def append_set(properties={})
    append 'people.set', properties_hash(properties, PERSON_PROPERTIES)
  end

  def append_set_once(properties = {})
    append 'people.set_once', properties_hash(properties, PERSON_PROPERTIES)
  end

  def append_increment(property, increment=1)
    append 'people.increment', property, increment
  end

  def append_track_charge(amount)
    append 'people.track_charge', amount
  end

  def append_register(properties={})
    append 'register', properties_hash(properties, PERSON_PROPERTIES)
  end

  def append_register_once(properties={})
    append 'register_once', properties_hash(properties, PERSON_PROPERTIES)
  end

  def append_identify(distinct_id)
    append 'identify', distinct_id
  end

  protected

  def engage(action, request_properties_or_distinct_id, properties, options)
    default = {:async => @async, :url => PERSON_URL}
    options = default.merge(options)

    request_properties = person_request_properties(request_properties_or_distinct_id)

    if action == :unset
      data = build_person_unset request_properties, properties
    else
      data = build_person action, request_properties, properties
    end

    parse_response post_request(options[:url], { :data => encoded_data(data) }, options[:async])
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

  def build_person_unset(request_properties, property)
    properties_hash(request_properties, PERSON_REQUEST_PROPERTIES).merge({ "$unset".to_sym => [property] })
  end
end
