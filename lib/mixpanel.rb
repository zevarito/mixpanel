require 'mixpanel/tracker'

module Mixpanel
  def self.new(token, env, options={})
    Kernel.warn("DEPRECATED: Use Mixpanel::Tracker.new instead")
    Mixpanel::Tracker.new(token, env, options)
  end
end
