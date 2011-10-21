def mixpanel_queue_should_include(mixpanel, type, *arguments)
  mixpanel.queue.each do |event_type, event_arguments|
    event_arguments.should == arguments.map{|arg| arg.to_json}
    event_type.should == type
  end
end
