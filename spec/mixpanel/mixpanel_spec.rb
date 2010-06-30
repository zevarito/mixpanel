require 'spec_helper'

describe Mixpanel do
  context "Accessing Mixpanel through javascript API" do
    before do
      @mixpanel = Mixpanel.new(MIX_PANEL_TOKEN)
    end

    context "Initializing object" do
      it "should have an instance variable for token and actions" do
        @mixpanel.instance_variables.should include("@token", "@actions")
      end
    end

    context "Appending actions" do
      it "should append simple actions" do
        @mixpanel.append_action("Sign up")
        mixpanel_actions_should_include(@mixpanel, "Sign up", {})
      end

      it "should append actions with metadata" do
        @mixpanel.append_action("Sign up", {:referer => 'http://example.com'})
        mixpanel_actions_should_include(@mixpanel, "Sign up", {:referer => 'http://example.com'})
      end

      it "should give direct access to actions" do
        @mixpanel.append_action("Sign up", {:referer => 'http://example.com'})
        @mixpanel.actions.size.should == 1
      end
    end
  end
end
