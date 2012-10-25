require 'spec_helper'

describe Mixpanel::Tracker do
  before(:each) do
    @mixpanel = Mixpanel::Tracker.new MIX_PANEL_TOKEN, { :env => {"REMOTE_ADDR" => "127.0.0.1"} }
  end

  context "Initializing object" do
    it "should have an instance variable for token and events" do
      @mixpanel.instance_variables.map(&:to_s).should include('@token', '@async', '@persist', '@env')
    end
  end

  context "Cleaning appended events" do
    it "should clear the queue" do
      @mixpanel.append_track("Sign up")
      @mixpanel.queue.size.should == 1
      @mixpanel.queue.clear
      @mixpanel.queue.size.should == 0
    end
  end

  context "Accessing Mixpanel through direct request" do
    context "Tracking events" do
      it "should track simple events" do
        @mixpanel.track("Sign up").should == true
      end
      
      it "should track events with properties" do
        @mixpanel.track('Sign up', { :likeable => true }, { :api_key => 'asdf' }).should == true
      end
    end
    
    context "Importing events" do
      it "should import simple events" do
        @mixpanel.import('Sign up').should == true
      end
      
      it "should import events with properties" do
        @mixpanel.import('Sign up', { :likeable => true }, { :api_key => 'asdf' }).should == true
      end
    end
    
    context "Engaging people" do
      it "should set attributes" do
        @mixpanel.set('person-a', { :email => 'me@domain.com', :likeable => false }).should == true
      end
      
      it "should increment attributes" do
        @mixpanel.increment('person-a', { :tokens => 3, :money => -1 }).should == true
      end
    end
  end

  context "Accessing Mixpanel through javascript API" do
    context "Appending events" do
      it "should store the event under the appropriate key" do
        @mixpanel.instance_variable_get(:@env).has_key?("mixpanel_events").should == true
      end

      it "should be the same the queue than env['mixpanel_events']" do
        @mixpanel.instance_variable_get(:@env)['mixpanel_events'].object_id.should == @mixpanel.queue.object_id
      end

      it "should append simple events" do
        props = { :time => Time.now, :ip => 'ASDF' }
        @mixpanel.append_track "Sign up", props
        mixpanel_queue_should_include(@mixpanel, "track", "Sign up", props)
      end

      it "should append events with properties" do
        props = { :referer => 'http://example.com', :time => Time.now, :ip => 'ASDF' }
        @mixpanel.append_track "Sign up", props
        mixpanel_queue_should_include(@mixpanel, "track", "Sign up", props)
      end

      it "should give direct access to queue" do
        @mixpanel.append_track("Sign up", {:referer => 'http://example.com'})
        @mixpanel.queue.size.should == 1
      end

      it "should allow identify to be called through the JS api" do
        @mixpanel.append_identify "some@one.com"
        mixpanel_queue_should_include(@mixpanel, "identify", "some@one.com")
      end

      it "should allow people.identify to be called through the JS api" do
        @mixpanel.append_people_identify "an_identity"
        mixpanel_queue_should_include(@mixpanel, "people.identify", "an_identity")
      end

      it "should allow the tracking of super properties in JS" do
        props = {:user_id => 12345, :gender => 'male'}
        @mixpanel.append_register props
        mixpanel_queue_should_include(@mixpanel, 'register', props)
      end
    end
  end

  context "Accessing Mixpanel asynchronously" do
    it "should open a subprocess successfully" do
      w = Mixpanel::Tracker.worker
      w.should == Mixpanel::Tracker.worker
    end

    it "should be able to write lines to the worker" do
      w = Mixpanel::Tracker.worker

      #On most systems this will exceed the pipe buffer size
      8.times do
        9000.times do
          w.write("\n")
        end
        sleep 0.1
      end
    end

    it "should dispose of a worker" do
      w = Mixpanel::Tracker.worker
      Mixpanel::Tracker.dispose_worker(w)

      w.closed?.should == true
      w2 = Mixpanel::Tracker.worker
      w2.should_not == w
    end
  end
end
