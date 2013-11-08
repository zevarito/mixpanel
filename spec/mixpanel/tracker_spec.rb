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

      it "should track simple events with async" do
        @mixpanel.track("Sign up", {}, :async => true).should == true
      end
    end

    context "Tracking pixel" do
      it "should return a URL" do
        @mixpanel.tracking_pixel("Sign up").should be_a(String)
      end

      it "should include img=1" do
        @mixpanel.tracking_pixel("Sign up").should match(/&img=1/)
      end
    end

    context "Redirect url" do
      let(:url) { "http://example.com?foo=bar&bar=foo" }

      it "should return a URL" do
        @mixpanel.redirect_url("Click Email", url).should be_a(String)
      end

      it "should include a redirect" do
        encoded_url = CGI::escape(url)
        @mixpanel.redirect_url("Click Email", url).should include('&redirect=' + encoded_url)
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

    describe '#alias' do
      it 'tracks a simple event' do
        @mixpanel.alias('James Salter').should be true
      end

      it 'tracks a $create_alias event to the TRACK_URL' do
        @mixpanel.should_receive(:track_event).with('$create_alias', anything, {}, Mixpanel::Event::TRACK_URL)
        @mixpanel.alias('Phillip Dean')
      end

      it 'includes the aliased name in the properties' do
        @mixpanel.should_receive(:track_event).with('$create_alias', { :alias => 'Cristina Wheatland' }, {}, Mixpanel::Event::TRACK_URL)
        @mixpanel.alias('Cristina Wheatland')
      end
    end

    context "Engaging people" do
      it "should set attributes" do
        @mixpanel.set('person-a', { :email => 'me@domain.com', :likeable => false }).should == true
      end

      it "should set an attribute once" do
        @mixpanel.set_once('person-a', { :email => 'me@domain.com', :likeable => false }).should == true
      end

      it "should set attributes with request properties" do
        @mixpanel.set({ :distinct_id => 'person-a', :ignore_time => true },  { :email => 'me@domain.com', :likeable => false }).should == true
      end

      it "should increment attributes" do
        @mixpanel.increment('person-a', { :tokens => 3, :money => -1 }).should == true
      end

      it "should track charges" do
        @mixpanel.track_charge('person-a', 20.0).should == true
      end

      it "should reset charges" do
        @mixpanel.reset_charges('person-a').should == true
      end

      it "should unset property" do
        @mixpanel.unset('person-a', 'property').should == true
      end

      it "should delete a user from mixpanel" do
        @mixpanel.delete('person-a').should == true
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
        time = Time.now
        props = { :time => time, :ip => 'ASDF' }
        @mixpanel.append_track "Sign up", props
        props[:time] = time.to_i
        mixpanel_queue_should_include(@mixpanel, "track", "Sign up", props)
      end

      it "should append events with properties" do
        time = Time.now
        props = { :referer => 'http://example.com', :time => time, :ip => 'ASDF' }
        @mixpanel.append_track "Sign up", props
        props[:time] = time.to_i
        mixpanel_queue_should_include(@mixpanel, "track", "Sign up", props)
      end

      it "should sanitize property values" do
        @mixpanel.append_track("Sign up", {:referer => "</script><script>alert('XSS');</script>"})
        @mixpanel.queue.size.should == 1
        enqueued = @mixpanel.queue.first
        properties_json = enqueued[1][1]
        properties_json.should_not match(%r|</script>|)
      end

      it "should be able to sanitize complex objects" do
        properties = {'object' => ['foo', {2 => 1, 1 => ['bar', Time.now, nil, {'xss' => "</script><script>alert('XSS');</script>"}]}]}
        @mixpanel.append_track("Sign up", properties)
        @mixpanel.queue.size.should == 1
        enqueued = @mixpanel.queue.first
        properties_json = enqueued[1][1]
        properties_json.should_not match(%r|</script>|)
      end


      it "should give direct access to queue" do
        @mixpanel.append_track("Sign up", {:referer => 'http://example.com'})
        @mixpanel.queue.size.should == 1
      end

      it "should allow identify to be called through the JS api" do
        @mixpanel.append_identify "some@one.com"
        mixpanel_queue_should_include(@mixpanel, "identify", "some@one.com")
      end

      it "should allow the tracking of super properties in JS" do
        props = {:user_id => 12345, :gender => 'male'}
        @mixpanel.append_register props
        mixpanel_queue_should_include(@mixpanel, 'register', props)
      end

      it "should allow the tracking of charges in JS" do
        @mixpanel.append_track_charge 40
        mixpanel_queue_should_include(@mixpanel, 'people.track_charge', 40)
      end

      it "should allow alias to be called through the JS api" do
        @mixpanel.append_alias "new_id"
        mixpanel_queue_should_include(@mixpanel, "alias", "new_id")
      end

      it "should allow the one-time tracking of super properties in JS" do
        props = {:user_id => 12345, :gender => 'male'}
        @mixpanel.append_register_once props
        mixpanel_queue_should_include(@mixpanel, 'register_once', props)
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
          w.write("")
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

  describe '#properties_hash' do
    it "base64encodes json formatted data" do
      properties = { :a => 4, :b => "foo"}
      special_properties = ["a"]
      hash = @mixpanel.send(:properties_hash, properties, special_properties)
      hash.should eq({ :'$a' => 4, :b => "foo"})
    end

    it "converts Time objects into integers" do
      time = Time.new
      properties = { :a => time, :b => "foo"}
      special_properties = []
      hash = @mixpanel.send(:properties_hash, properties, special_properties)
      hash.should eq({ :a => time.to_i, :b => "foo"})
    end
  end
end
