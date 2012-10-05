require "open-uri"
require 'base64'
require 'json'
require 'thread'

class Mixpanel
  require 'mixpanel/async'
  require 'mixpanel/event'
  require 'mixpanel/person'
  
  extend Mixpanel::Async
  include Mixpanel::Event
  include Mixpanel::Person
  
  def initialize token, options={}
    @token = token
    @async = !!options.fetch(:async, false)
    @persist = !!options.fetch(:persist, false)
    @env = options.fetch :env, {}
    @api_key = options.fetch :api_key, nil
    
    # Make sure queue object is instantiated to an array.  If not persisted, set queue object to empty array.
    if @persist
      @env['rack.session'] ||= {}
      @env['rack.session']['mixpanel_events'] ||= []
    else
      @env['mixpanel_events'] = []
    end
  end
  
  def queue
    @persist ? @env['rack.session']['mixpanel_events'] : @env['mixpanel_events']
  end
  
  def append type, *args
    queue << [type, args.collect {|arg| arg.to_json}]
  end
  
  protected
  
  # Walk through each property and see if it is in the special_properties.  If so, change the key to have a $ in front of it.
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
    async ? send_async(url) : open(url).read
  end
  
  def parse_response response
    response.to_i == 1
  end
  
  def send_async url
    w = Mixpanel.worker
    begin
      url << "\n"
      w.write url
    rescue Errno::EPIPE => e
      Mixpanel.dispose_worker w
    end
  end
end
