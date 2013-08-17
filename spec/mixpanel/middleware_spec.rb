require 'spec_helper'

def exec_default_appends_on(mixpanel)
  mixpanel.append_track("Visit", {:article => 1})
  mixpanel.append_track("Sign in")
  mixpanel.append_set(:first_name => "foo", :last_name => "bar", :username => "foobar")
  mixpanel.append_increment(:sign_in_rate)
end

def check_for_default_appends_on(txt)
  txt.should =~ /mixpanel\.track\("Visit",\s?\{.*"article":1/
  txt.should =~ /mixpanel\.track\("Sign in",\s?\{.*"time":.*\}/
  txt.should =~ /mixpanel\.people\.set\(.*\);\nmixpanel.people.increment\(\"sign_in_rate\",\s?1\);/
  match = txt.match(/mixpanel\.people\.set\((.*\));/)
  match[1].should =~ /\"\$first_name\":\"foo\"/
  match[1].should =~ /\"\$username\":\"foobar\"/
  match[1].should =~ /\"\$last_name\":\"bar\"/
  txt.should =~ /mixpanel\.people\.increment\(\"sign_in_rate\"\s?,\s?1\)/
end

describe Mixpanel::Middleware do
  include Rack::Test::Methods

  describe "Dummy apps, no text/html" do
    before do
      setup_rack_application(DummyApp, :body => html_document, :headers => {})
      get "/"
    end

    it "should pass through if the document is not text/html content type" do
      last_response.body.should == html_document
    end
  end

  describe "Dummy app, handles skip requests properly" do
    before do
      setup_rack_application(DummyApp, {:body => html_document, :headers => {"Content-Type" => "text/html"}})
    end

    it "should not append mixpanel scripts with skip request" do
      get "/", {}, {"HTTP_SKIP_MIXPANEL_MIDDLEWARE" => true}
      Nokogiri::HTML(last_response.body).search('script').should be_empty
    end

    it "should append mixpanel scripts without skip request" do
      get "/"
      Nokogiri::HTML(last_response.body).search('script').size.should == 1
    end

    it "should skip requests in the 3xx range" do
      setup_rack_application(DummyApp, :body => html_document, :headers => {"Content-Type" => "text/html"}, :status => 350)
      get "/"
      Nokogiri::HTML(last_response.body).search('script').should be_empty
    end

    context "when disabling with #skip_this_request" do
      before{ Mixpanel::Middleware.skip_this_request }

      it "should skip this request but not the next request" do
        get "/"
        Nokogiri::HTML(last_response.body).search('script').should be_empty
        get "/"
        Nokogiri::HTML(last_response.body).search('script').size.should == 1
      end

    end
  end

  describe "Appending async mixpanel scripts" do
    describe "With ajax requests" do
      before do
        setup_rack_application(DummyApp, {:body => html_document, :headers => {"Content-Type" => "text/html"}})
        get "/", {}, {"HTTP_X_REQUESTED_WITH" => "XMLHttpRequest"}
      end

      it "should not append mixpanel scripts to head element" do
        Nokogiri::HTML(last_response.body).search('script').should be_empty
      end

      it "should not update Content-Length in headers" do
        last_response.headers["Content-Length"].should == html_document.length.to_s
      end
    end

    describe "With large ajax response" do
      before do
        setup_rack_application(DummyApp, {:body => large_script, :headers => {"Content-Type" => "text/html"}})
        get "/", {}, {"HTTP_X_REQUESTED_WITH" => "XMLHttpRequest"}
      end

      it "should not append mixpanel scripts to head element" do
        last_response.body.index('window.mixpanel').should be_nil
      end

      it "should pass through if the document is not text/html content type" do
        last_response.body.should == large_script
      end
    end

    describe "With regular requests" do
      describe "With js in head" do
        before do
          setup_rack_application(DummyApp, {:body => html_document, :headers => {"Content-Type" => "text/html"}}, {:insert_js_last => false})
          get "/"
        end

        it "should append mixpanel scripts to head element" do
          Nokogiri::HTML(last_response.body).search('head script').should_not be_empty
          Nokogiri::HTML(last_response.body).search('body script').should be_empty
        end

        it "should have 1 included script" do
          Nokogiri::HTML(last_response.body).search('script').size.should == 1
        end

        it "should use the specified token instantiating mixpanel lib" do
          last_response.body.should =~ /mixpanel\.init\("#{MIX_PANEL_TOKEN}"\)/
        end

        it "should define Content-Length if not exist" do
          last_response.headers.has_key?("Content-Length").should == true
        end

        it "should update Content-Length in headers" do
          last_response.headers["Content-Length"].should_not == html_document.length.to_s
        end
      end

      describe "With js last" do
        before do
          setup_rack_application(DummyApp, {:body => html_document, :headers => {"Content-Type" => "text/html"}}, {:insert_js_last => true})
          get "/"
        end

        it "should append mixpanel scripts to end of body element" do
          Nokogiri::HTML(last_response.body).search('head script').should be_empty
          Nokogiri::HTML(last_response.body).search('body script').should_not be_empty
        end
      end
    end
  end

  describe "Appending mixpanel scripts" do
    describe "With ajax requests" do
      before do
        setup_rack_application(DummyApp, :body => html_document, :headers => {"Content-Type" => "text/html"})
        get "/", {}, {"HTTP_X_REQUESTED_WITH" => "XMLHttpRequest"}
      end

      it "should not append mixpanel scripts to head element" do
        Nokogiri::HTML(last_response.body).search('script').should be_empty
      end

      it "should not update Content-Length in headers" do
        last_response.headers["Content-Length"].should == html_document.length.to_s
      end
    end

    describe "With large ajax response" do
      before do
        setup_rack_application(DummyApp, :body => large_script, :headers => {"Content-Type" => "text/html"})
        get "/", {}, {"HTTP_X_REQUESTED_WITH" => "XMLHttpRequest"}
      end

      it "should not append mixpanel scripts to head element" do
        last_response.body.index('window.mixpanel').should be_nil
      end

      it "should pass through if the document is not text/html content type" do
        last_response.body.should == large_script
      end
    end

    describe "With regular requests" do
      describe "With js in head" do
        before do
          setup_rack_application(DummyApp, {:body => html_document, :headers => {"Content-Type" => "text/html"}}, {:insert_js_last => false})
          get "/"
        end

        it "should append mixpanel scripts to head element" do
          Nokogiri::HTML(last_response.body).search('head script').should_not be_empty
          Nokogiri::HTML(last_response.body).search('body script').should be_empty
        end

        it "should have 1 included script" do
          Nokogiri::HTML(last_response.body).search('script').size.should == 1
        end

        it "should use the specified token instantiating mixpanel lib" do
          last_response.body.should =~ /mixpanel\.init\("#{MIX_PANEL_TOKEN}"\)/
        end

        it "should define Content-Length if not exist" do
          last_response.headers.has_key?("Content-Length").should == true
        end

        it "should update Content-Length in headers" do
          last_response.headers["Content-Length"].should_not == html_document.length.to_s
        end
      end

      describe "With js last" do
        before do
          setup_rack_application(DummyApp, {:body => html_document, :headers => {"Content-Type" => "text/html"}}, {:insert_js_last => true})
          get "/"
        end

        it "should append mixpanel scripts to end of body element" do
          Nokogiri::HTML(last_response.body).search('head script').should be_empty
          Nokogiri::HTML(last_response.body).search('body script').should_not be_empty
        end
      end

      describe "With no mixpanel scripts" do
        before do
          setup_rack_application(DummyApp, {:body => html_document, :headers => {"Content-Type" => "text/html"}}, {:insert_mixpanel_scripts => false})
          get "/"
        end

        it "should not insert mixpanel scripts" do
          Nokogiri::HTML(last_response.body).search('head script').should be_empty
          Nokogiri::HTML(last_response.body).search('body script').should be_empty
        end
      end
    end
  end

  describe "Tracking async appended events" do
    before do
      @mixpanel = Mixpanel::Tracker.new MIX_PANEL_TOKEN
      exec_default_appends_on @mixpanel
    end

    describe "With ajax requests and text/html response" do
      before do
        setup_rack_application(DummyApp, {:body => "<p>response</p>", :headers => {"Content-Type" => "text/html"}})

        get "/", {}, {"mixpanel_events" => @mixpanel.queue, "HTTP_X_REQUESTED_WITH" => "XMLHttpRequest"}
      end

      it "should render only one script tag" do
        Nokogiri::HTML(last_response.body).search('script').size.should == 1
      end

      it "should be tracking the correct events inside a script tag" do
        script = Nokogiri::HTML(last_response.body).search('script')
        check_for_default_appends_on script.inner_html
      end

      it "should delete events queue after use it" do
        last_request.env.has_key?("mixpanel_events").should == false
      end
    end

    describe "With ajax requests and text/javascript response" do
      before do
        setup_rack_application(DummyApp, {:body => "alert('response')", :headers => {"Content-Type" => "text/javascript"}})
        get "/", {}, {"mixpanel_events" => @mixpanel.queue, "HTTP_X_REQUESTED_WITH" => "XMLHttpRequest"}
      end

      it "should not render a script tag" do
        Nokogiri::HTML(last_response.body).search('script').size.should == 0
      end

      it "should be tracking the correct events inside a try/catch" do
        script = last_response.body.match(/try\s?\{(.*)\}\s?catch/m)[1]
        check_for_default_appends_on script
      end

      it "should delete events queue after use it" do
        last_request.env.has_key?("mixpanel_events").should == false
      end
    end

    describe "With regular requests" do
      before do
        setup_rack_application(DummyApp, {:body => html_document, :headers => {"Content-Type" => "text/html"}})

        get "/", {}, {"mixpanel_events" => @mixpanel.queue}
      end

      it "should render 2 script tags" do
        Nokogiri::HTML(last_response.body).search('script').size.should == 2
      end

      it "should be tracking the correct events" do
        check_for_default_appends_on last_response.body
      end

      it "should delete events queue after use it" do
        last_request.env.has_key?("mixpanel_events").should == false
      end
    end

    describe "With turbolinks" do
      before do
        setup_rack_application(DummyApp, {
          :body => ['',html_document],
          :headers => {'Content-Type' => 'text/html'}
        }, {:insert_js_last => true})
        get '/', {}, {'HTTP_X_XHR_REFERER' => '/', 'mixpanel_events' => @mixpanel.queue}
      end

      it "should append mixpanel scripts to end of body element" do
        Nokogiri::HTML(last_response.body).search('head script').should be_empty
        Nokogiri::HTML(last_response.body).search('body script').should_not be_empty
      end
    end
  end

  describe "Tracking appended events" do
    before do
      @mixpanel = Mixpanel::Tracker.new MIX_PANEL_TOKEN
      exec_default_appends_on @mixpanel
    end

    describe "With ajax requests and text/html response" do
      before do
        setup_rack_application(DummyApp, :body => "<p>response</p>", :headers => {"Content-Type" => "text/html"})

        get "/", {}, {"mixpanel_events" => @mixpanel.queue, "HTTP_X_REQUESTED_WITH" => "XMLHttpRequest"}
      end

      it "should render only one script tag" do
        Nokogiri::HTML(last_response.body).search('script').size.should == 1
      end

      it "should be tracking the correct events inside a script tag" do
        script = Nokogiri::HTML(last_response.body).search('script')
        check_for_default_appends_on script.inner_html
      end

      it "should delete events queue after use it" do
        last_request.env.has_key?("mixpanel_events").should == false
      end
    end

    describe "With ajax requests and text/javascript response" do
      before do
        setup_rack_application(DummyApp, :body => "alert('response')", :headers => {"Content-Type" => "text/javascript"})
        get "/", {}, {"mixpanel_events" => @mixpanel.queue, "HTTP_X_REQUESTED_WITH" => "XMLHttpRequest"}
      end

      it "should not render a script tag" do
        Nokogiri::HTML(last_response.body).search('script').size.should == 0
      end

      it "should be tracking the correct events inside a try/catch" do
        script = last_response.body.match(/try\s?\{(.*)\}\s?catch/m)[1]
        check_for_default_appends_on script
      end

      it "should delete events queue after use it" do
        last_request.env.has_key?("mixpanel_events").should == false
      end
    end

    describe "With regular requests" do
      before do
        setup_rack_application(DummyApp, :body => html_document, :headers => {"Content-Type" => "text/html"})

        get "/", {}, {"mixpanel_events" => @mixpanel.queue}
      end

      it "should render 2 script tags" do
        Nokogiri::HTML(last_response.body).search('script').size.should == 2
      end

      it "should be tracking the correct events" do
        check_for_default_appends_on last_response.body
      end

      it "should delete events queue after use it" do
        last_request.env.has_key?("mixpanel_events").should == false
      end
    end
  end
end
