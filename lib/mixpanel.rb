require "open-uri"
require 'base64'
require 'json'
require 'thread'
require 'mixpanel/event'
require 'mixpanel/person'

class Mixpanel
  include Event
  include Person
  
  def initialize token, options={}
    @token = token
    @async = options.fetch(:async, false)
    @persist = options.fetch(:persist, false)
    @env = options.fetch(:env, {})
    
    if @persist
      queue ||= []
    else
      clear_queue
    end
  end
  
  protected
  
  def properties_hash properties, special_properties
    properties.inject({}) do |props, (key, value)|
      key = "$#{key}" if special_properties.include?(key.to_s)
      props[key.to_sym] = value
      props
    end
  end
  
  def encoded_data parameters
    Base64.encode64(JSON.generate(parameters)).gsub(/\n/,'')
  end
  
  def request url, async
    if async
      # TODO: Wire this up again
    else
      open(url).read
    end
  end
  
  def parse_response response
    response.to_i == 1
  end
  
  def queue
    @persist ? @env["rack.session"]["mixpanel_events"] : @env["mixpanel_events"]
  end
  
  def clear_queue
    queue = []
  end
  
  def append type, *args
    queue << [type, args.collect {|arg| arg.to_json}]
  end
end
