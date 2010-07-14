require 'ruby-debug'
require File.join(File.dirname(__FILE__), "../lib", "mixpanel")
require 'rack/test'
require 'fakeweb'
require 'nokogiri'
Dir[File.expand_path(File.join(File.dirname(__FILE__),'support','**','*.rb'))].each {|f| require f}

MIX_PANEL_TOKEN = "e2d8b0bea559147844ffab3d607d26a6"

def mixpanel_queue_should_include(mixpanel, event, properties)
  mixpanel.queue.each do |event_hash|
    event_hash[:event].should == event
    event_hash[:properties].should == properties if properties
  end
end

# Fakeweb
FakeWeb.allow_net_connect = false
FakeWeb.register_uri(:any, /http:\/\/api\.mixpanel\.com.*/, :body => "1")
