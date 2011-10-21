require File.expand_path("../lib/mixpanel", File.dirname(__FILE__))

require 'ruby-debug'
require 'rack/test'
require 'fakeweb'
require 'nokogiri'

Dir[File.expand_path(File.join(File.dirname(__FILE__),'support','**','*.rb'))].each {|f| require f}

MIX_PANEL_TOKEN = "e2d8b0bea559147844ffab3d607d26a6"

# Fakeweb
FakeWeb.allow_net_connect = false
FakeWeb.register_uri(:any, /http:\/\/api\.mixpanel\.com.*/, :body => "1")
