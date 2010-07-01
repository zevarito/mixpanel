require 'spec_helper'

describe Mixpanel do
  before do
    @mixpanel = Mixpanel.new(MIX_PANEL_TOKEN)
  end

  context "Initializing object" do
    it "should have an instance variable for token and events" do
      @mixpanel.instance_variables.should include("@token", "@events")
    end
  end

  context "Accessing Mixpanel through javascript API" do
    context "Appending events" do
      it "should append simple events" do
        @mixpanel.append_event("Sign up")
        mixpanel_events_should_include(@mixpanel, "Sign up", {})
      end

      it "should append events with properties" do
        @mixpanel.append_event("Sign up", {:referer => 'http://example.com'})
        mixpanel_events_should_include(@mixpanel, "Sign up", {:referer => 'http://example.com'})
      end

      it "should give direct access to events" do
        @mixpanel.append_event("Sign up", {:referer => 'http://example.com'})
        @mixpanel.events.size.should == 1
      end
    end
  end
end
