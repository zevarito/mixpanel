require 'spec_helper'

describe Middleware do
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

    describe "With regular requests" do
      before do
        setup_rack_application(DummyApp, :body => html_document, :headers => {"Content-Type" => "text/html"})
        get "/"
      end

      it "should append mixpanel scripts to head element" do
        Nokogiri::HTML(last_response.body).search('head script').should_not be_empty
        Nokogiri::HTML(last_response.body).search('body script').should be_empty
      end

      it "should have 2 included scripts" do
        Nokogiri::HTML(last_response.body).search('script').size.should == 2
      end

      it "should use the specified token instantiating mixpanel lib" do
        last_response.should =~ /new MixpanelLib\('#{MIX_PANEL_TOKEN}'\)/
      end

      it "should define Content-Length if not exist" do
        last_response.headers.has_key?("Content-Length").should == true
      end

      it "should update Content-Length in headers" do
        last_response.headers["Content-Length"].should_not == html_document.length.to_s
      end
    end
  end

  describe "Tracking appended events" do
    before do
      @mixpanel = Mixpanel.new(MIX_PANEL_TOKEN, {})
      @mixpanel.append_event("Visit", {:article => 1})
      @mixpanel.append_event("Sign in")
    end

    describe "With ajax requests and text/html response" do
      before do
        setup_rack_application(DummyApp, :body => html_document, :headers => {"Content-Type" => "text/html"})

        get "/", {}, {"mixpanel_events" => @mixpanel.queue, "HTTP_X_REQUESTED_WITH" => "XMLHttpRequest"}
      end

      it "should render only one script tag" do
        Nokogiri::HTML(last_response.body).search('script').size.should == 1
      end

      it "should be tracking the correct events inside a script tag" do
        script = Nokogiri::HTML(last_response.body).search('script')
        script.inner_html.should =~ /mpmetrics\.track\("Visit",\s?\{"article":1\}\)/
        script.inner_html.should =~ /mpmetrics\.track\("Sign in",\s?\{\}\)/
      end
    end

    describe "With regular requests" do
      before do
        setup_rack_application(DummyApp, :body => html_document, :headers => {"Content-Type" => "text/html"})

        get "/", {}, {"mixpanel_events" => @mixpanel.queue}
      end

      it "should be tracking the correct events" do
        last_response.body.should =~ /mpmetrics\.track\("Visit",\s?\{"article":1\}\)/
        last_response.body.should =~ /mpmetrics\.track\("Sign in",\s?\{\}\)/
      end
    end
  end
end
