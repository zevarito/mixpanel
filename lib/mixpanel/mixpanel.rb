require "open-uri"
require 'base64'
require 'json'

class Mixpanel
  def initialize(token, env)
    @token = token
    @env = env
    clear_queue
  end

  def append_event(event, properties = {})
    queue << build_event(event, properties)
  end

  def track_event(event, properties = {})
    params = build_event(event, properties.merge(:token => @token, :time => Time.now.utc.to_i, :ip => ip))
    parse_response request(params)
  end

  def ip
    @env.has_key?("REMOTE_ADDR") ? @env["REMOTE_ADDR"] : ""
  end

  def queue
    @env["mixpanel_events"]
  end

  def clear_queue
    @env["mixpanel_events"] = []
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
