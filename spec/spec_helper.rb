begin
  require File.expand_path('../.bundle/environment', __FILE__)
rescue LoadError
  require 'rubygems'
  require 'bundler'
  Bundler.setup(:default, :test)
end

require File.join(File.dirname(__FILE__), "../lib", "mixpanel")
require 'fakeweb'

MIX_PANEL_TOKEN = "e2d8b0bea559147844ffab3d607d26a6"

def mixpanel_events_should_include(mixpanel, event, properties)
  mixpanel.events.each do |event_hash|
    event_hash[:event].should == event
    event_hash[:properties].should == properties if properties
  end
end

# Fakeweb
FakeWeb.allow_net_connect = false
FakeWeb.register_uri(:any, /http:\/\/api\.mixpanel\.com.*/, :body => "1")
