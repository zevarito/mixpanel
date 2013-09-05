require File.join(File.dirname(__FILE__), "../lib", "mixpanel")
require 'rack/test'
require 'fakeweb'
require 'nokogiri'
require 'cgi'

Dir[File.expand_path(File.join(File.dirname(__FILE__),'support','**','*.rb'))].each {|f| require f}

MIX_PANEL_TOKEN = "e2d8b0bea559147844ffab3d607d26a6"

# json hashes have string keys, convert to json and back to compare hashes
def mixpanel_queue_should_include(mixpanel, type, *arguments)
  event = mixpanel.queue.detect { |event| event[0] == type }
  event.should_not be_nil
  event_arguments = event[1]
  unjsonify(event_arguments).should == json_and_back(arguments)
end

def json_and_back array
  unjsonify array.collect { |arg| arg.to_json }
end

def unjsonify array
  array.collect { |arg| JSON.parse(arg) rescue arg }
end

# Fakeweb
FakeWeb.allow_net_connect = false
FakeWeb.register_uri(:any, /http:\/\/api\.mixpanel\.com.*/, :body => "1")
