require 'ruby-debug'
require File.join(File.dirname(__FILE__), "../lib", "mixpanel")
require 'rack/test'
require 'fakeweb'
require 'nokogiri'
Dir[File.expand_path(File.join(File.dirname(__FILE__),'support','**','*.rb'))].each {|f| require f}

MIX_PANEL_TOKEN = "e2d8b0bea559147844ffab3d607d26a6"


def mixpanel_queue_should_include(mixpanel, type, *arguments)
  mixpanel.queue.each do |event_type, event_arguments|
    event_arguments.should == arguments.map{|arg| arg.to_json}
    event_type.should == type
  end
end

# Fakeweb
FakeWeb.allow_net_connect = false
FakeWeb.register_uri(:any, /http:\/\/api\.mixpanel\.com.*/, :body => "1")

module SpecHelper
  def self.stub_time_dot_now(desired_time)
    Time.class_eval do
      class << self
        alias original_now now
      end
    end
    (class << Time; self; end).class_eval do
      define_method(:now) { desired_time }
    end
    yield
  ensure
    Time.class_eval do
      class << self
        alias now original_now
      end
    end
  end
end
