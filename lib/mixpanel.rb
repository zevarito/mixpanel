class Mixpanel
  attr_accessor :events

  def initialize(token, options = {})
    @token = token
    @events = []
  end

  def append_event(event, properties = {})
    @events << build_event(event, properties)
  end

  private

  def build_event(event, properties)
    {:event => event, :properties => properties}
  end
end
