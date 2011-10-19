require 'logger'
require 'mixpanel/configuration'
require 'mixpanel/tracker'

module Mixpanel
  def self.new(token, env, async = false)
    Kernel.warn("DEPRECATED: Use Mixpanel::Tracker.new instead")
    Mixpanel::Tracker.new(token, env, async)
  end
end
