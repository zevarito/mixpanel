require 'spec_helper'

describe Mixpanel::Configuration do
  describe "logger" do
    it "defaults to logging to stdout with log_level info" do
      config = Mixpanel::Configuration.new
      config.logger.level.should == Logger::DEBUG
    end

    it "lazily initializes so that you can do Mixpanel::Configuration.logger.level = when configuring the client lib" do
      config = Mixpanel::Configuration.new :logger => nil
      config.logger.should_not == nil
    end
  end

  describe "self.logger" do
    it "lazily initializes so that you can do Mixpanel::Configuration.logger.level = when configuring the client lib" do
      Mixpanel::Configuration.logger = nil
      Mixpanel::Configuration.logger.should_not == nil
    end
  end

end
