require 'ruby-debug'
require File.join(File.dirname(__FILE__), "../lib", "mixpanel")
require 'rack/test'
require 'fakeweb'
require 'nokogiri'
require 'active_support/core_ext/hash'

Dir[File.expand_path(File.join(File.dirname(__FILE__),'support','**','*.rb'))].each {|f| require f}

MIX_PANEL_TOKEN = "e2d8b0bea559147844ffab3d607d26a6"


def mixpanel_queue_should_include(mixpanel, type, *arguments)
  mixpanel.queue.each do |event_type, event_arguments|
    # hashes store keys in an undetermined order.  convert to json and back and compare hash to hash, not json to json
    unjsonify(event_arguments).should == json_and_back(arguments)
  end
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
