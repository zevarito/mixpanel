class Mixpanel
  attr_accessor :actions

  def initialize(token, options = {})
    @token = token
    @actions = []
  end

  def append_action(action, metadata = {})
    @actions << build_action(action, metadata)
  end

  private

  def build_action(action, metadata)
    {:action => action, :metadata => metadata}
  end
end
