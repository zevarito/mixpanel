require File.join(File.dirname(__FILE__), "../lib", "mixpanel")


MIX_PANEL_TOKEN = "123456789"

def mixpanel_actions_should_include(mixpanel, action, metadata)
  mixpanel.actions.each do |action_hash|
    action_hash[:action].should == action
    action_hash[:metadata].should == metadata if metadata
  end
end
