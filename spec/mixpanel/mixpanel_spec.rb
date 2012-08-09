require 'spec_helper'

describe Mixpanel do
  context "Deprecated initialization mode" do
    it "should not allow to initialize the class as the old way" do
      lambda do
        mixpanel = Mixpanel.new(MIX_PANEL_TOKEN, @env = {"REMOTE_ADDR" => "127.0.0.1"})
      end.should raise_error(NoMethodError)
    end
  end
end
