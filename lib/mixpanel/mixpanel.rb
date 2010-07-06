require "open-uri"
require 'base64'
require 'json'

class Mixpanel
  attr_reader :queue

  def initialize(token, options = {})
    @token = token
    @queue = []
  end

  def append_event(event, properties = {})
    @queue << build_event(event, properties)
  end

  def track_event(event, properties = {})
    params = build_event(event, properties.merge(:token => @token, :time => Time.now.utc.to_i))
    parse_response request(params)
  end

  def clean_queue
    @queue = []
  end

  private

  def parse_response(response)
    response == "1" ? true : false
  end

  def request(params)
    data = Base64.encode64(JSON.generate(params)).gsub(/\n/,'')
    url = "http://api.mixpanel.com/track/?data=#{data}"

    open(url).read
  end

  def build_event(event, properties)
    {:event => event, :properties => properties}
  end
end
