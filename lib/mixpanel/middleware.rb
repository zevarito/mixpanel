require 'rack'
require 'json'

module Mixpanel
  class Middleware
    class << self
      attr_accessor :skip_request
      def skip_this_request
        @skip_request = true
      end
    end

    @skip_request = false

    def initialize(app, mixpanel_token, options={})
      @app = app
      @token = mixpanel_token
      @options = {
        :insert_mixpanel_scripts=> true,
        :insert_js_last => false,
        :persist => false,
        :config => {}
      }.merge(options)
    end

    def call(env)
      @env = env

      @status, @headers, @response = @app.call(env)

      if is_trackable_response? && !Mixpanel::Middleware.skip_request
        merge_queue! if @options[:persist]
        update_response!
        update_content_length!
        delete_event_queue!
      end

      Mixpanel::Middleware.skip_request = false

      [@status, @headers, @response]
    end

    private

    def update_response!
      @response.each do |part|
        if is_regular_request? && is_html_response?
          insert_at = part.index(@options[:insert_js_last] ? '</body' : '</head')
          unless insert_at.nil?
            part.insert(insert_at, render_event_tracking_scripts) unless queue.empty?
            if @options[:insert_mixpanel_scripts]
              part.insert(insert_at, render_mixpanel_scripts) #This will insert the mixpanel initialization code before the queue of tracking events.
            end
          end
        elsif is_turbolink_request? && is_html_response?
          insert_at = part.index('</body')
          part.insert(insert_at, render_event_tracking_scripts) unless insert_at.nil? or queue.empty?
        elsif is_ajax_request? && is_html_response?
          part.insert(0, render_event_tracking_scripts) unless queue.empty?
        elsif is_ajax_request? && is_javascript_response?
          part.insert(0, render_event_tracking_scripts(false)) unless queue.empty?
        end
      end
    end

    def update_content_length!
      new_size = 0
      @response.each{|part| new_size += part.bytesize}
      @headers.merge!("Content-Length" => new_size.to_s)
    end

    def is_regular_request?
      !is_ajax_request? && !is_turbolink_request?
    end

    def is_turbolink_request?
      @env.has_key?("HTTP_X_XHR_REFERER")
    end

    def is_ajax_request?
      @env.has_key?("HTTP_X_REQUESTED_WITH") && @env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    end

    def is_html_response?
      @headers["Content-Type"].include?("text/html") if @headers.has_key?("Content-Type")
    end

    def is_javascript_response?
      @headers["Content-Type"].include?("text/javascript") if @headers.has_key?("Content-Type")
    end

    def is_trackable_response?
      return false if (300..399).include?(@status.to_i)
      return false if @env.has_key?("HTTP_SKIP_MIXPANEL_MIDDLEWARE")
      is_html_response? || is_javascript_response?
    end

    def render_mixpanel_scripts
      <<-EOT
        <!-- start Mixpanel -->
        <script type="text/javascript">
          (function(e,b){if(!b.__SV){var a,f,i,g;window.mixpanel=b;a=e.createElement("script");a.type="text/javascript";a.async=!0;a.src=("https:"===e.location.protocol?"https:":"http:")+'//cdn.mxpnl.com/libs/mixpanel-2.2.min.js';f=e.getElementsByTagName("script")[0];f.parentNode.insertBefore(a,f);b._i=[];b.init=function(a,e,d){function f(b,h){var a=h.split(".");2==a.length&&(b=b[a[0]],h=a[1]);b[h]=function(){b.push([h].concat(Array.prototype.slice.call(arguments,0)))}}var c=b;"undefined"!==typeof d?c=b[d]=[]:d="mixpanel";c.people=c.people||[];c.toString=function(b){var a="mixpanel";"mixpanel"!==d&&(a+="."+d);b||(a+=" (stub)");return a};c.people.toString=function(){return c.toString(1)+".people (stub)"};i="disable track track_pageview track_links track_forms register register_once alias unregister identify name_tag set_config people.set people.set_once people.increment people.append people.track_charge people.clear_charges people.delete_user".split(" ");for(g=0;g<i.length;g++)f(c,i[g]);b._i.push([a,e,d])};b.__SV=1.2}})(document,window.mixpanel||[]);
          mixpanel.init("#{@token}");
          mixpanel.set_config(#{@options[:config].to_json});
        </script>
        <!-- end Mixpanel -->
      EOT
    end

    def delete_event_queue!
      if @options[:persist]
        (@env['rack.session']).delete('mixpanel_events')
      else
        @env.delete('mixpanel_events')
      end
    end

    def queue
      if @options[:persist]
        return [] if !(@env['rack.session']).has_key?('mixpanel_events') || @env['rack.session']['mixpanel_events'].empty?
        @env['rack.session']['mixpanel_events']
      else
        return [] if !@env.has_key?('mixpanel_events') || @env['mixpanel_events'].empty?
        @env['mixpanel_events']
      end
    end

    def merge_queue!
      present_hash = {}
      special_events = ['alias', 'identify', 'name_tag', 'people.set', 'register']
      queue.uniq!

      queue.reverse_each do |item|
        is_special = special_events.include?(item[0])
        if present_hash[item[0]] and is_special
          queue.delete(item)
        else
          present_hash[item[0]] = true if is_special
        end
      end
    end

    def render_event_tracking_scripts(include_script_tag=true)
      return "" if queue.empty?

      output = queue.map {|type, arguments| %(mixpanel.#{type}(#{arguments.join(', ')});) }.join("\n")
      output = "try {#{output}} catch(err) {};"

      include_script_tag ? "<script type='text/javascript'>#{output}</script>" : output
    end
  end
end

