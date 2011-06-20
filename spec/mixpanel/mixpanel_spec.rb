require 'spec_helper'

describe Mixpanel do
  context "Deprecated initialization mode" do
    it "should instantiate the object as it was doing before but drop a deprecation warning" do
      mixpanel = Mixpanel.new(MIX_PANEL_TOKEN, @env = {"REMOTE_ADDR" => "127.0.0.1"})
      mixpanel.should be_kind_of(Mixpanel::Tracker)
    end
  end
end
