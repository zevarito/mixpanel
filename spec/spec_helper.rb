require File.join(File.dirname(__FILE__), "../lib", "mixpanel")


MIX_PANEL_TOKEN = "123456789"

def mixpanel_events_should_include(mixpanel, event, properties)
  mixpanel.events.each do |event_hash|
    event_hash[:event].should == event
    event_hash[:properties].should == properties if properties
  end
end
