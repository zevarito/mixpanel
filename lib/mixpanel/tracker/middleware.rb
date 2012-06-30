require 'rack'
require 'json'

module Mixpanel
  class Tracker
    class Middleware
      def initialize(app, mixpanel_token, options={})
        @app = app
        @token = mixpanel_token
        @options = {
          :insert_js_last => false,
          :config => {}
        }.merge(options)
      end

      def call(env)
        @env = env

        @status, @headers, @response = @app.call(env)

        if is_trackable_response?
          update_response!
          update_content_length!
          delete_event_queue!
        end

        [@status, @headers, @response]
      end

      private

      def update_response!
        @response.each do |part|
          if is_regular_request? && is_html_response?
            insert_at = part.index(@options[:insert_js_last] ? '</body' : '</head')
            unless insert_at.nil?
              part.insert(insert_at, render_event_tracking_scripts) unless queue.empty?
              part.insert(insert_at, render_mixpanel_scripts) #This will insert the mixpanel initialization code before the queue of tracking events.
            end
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
        !is_ajax_request?
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
        is_html_response? || is_javascript_response?
      end

      def render_mixpanel_scripts
        <<-EOT
          <!-- start Mixpanel -->
          <script type="text/javascript">(function(c,b){var a,d,h,e;a=c.createElement("script");a.type="text/javascript";a.async=!0;a.src=("https:"===c.location.protocol?"https:":"http:")+'//api.mixpanel.com/site_media/js/api/mixpanel.2.js';d=c.getElementsByTagName("script")[0];d.parentNode.insertBefore(a,d);b._i=[];b.init=function(a,c,f){function d(a,b){var c=b.split(".");2==c.length&&(a=a[c[0]],b=c[1]);a[b]=function(){a.push([b].concat(Array.prototype.slice.call(arguments,0)))}}var g=b;"undefined"!==typeof f?g=
          b[f]=[]:f="mixpanel";g.people=g.people||[];h="disable track track_pageview track_links track_forms register register_once unregister identify name_tag set_config people.set people.increment".split(" ");for(e=0;e<h.length;e++)d(g,h[e]);b._i.push([a,c,f])};window.mixpanel=b})(document,window.mixpanel||[]);
          mixpanel.init("#{@token}");
          mixpanel.set_config(#{@options[:config].to_json});
          </script>
          <!-- end Mixpanel -->
        EOT
      end

      def delete_event_queue!
        @env.delete('mixpanel_events')
      end

      def queue
        return [] if !@env.has_key?('mixpanel_events') || @env['mixpanel_events'].empty?
        @env['mixpanel_events']
      end

      def render_event_tracking_scripts(include_script_tag=true)
        return "" if queue.empty?

        output = queue.map {|type, arguments| %(mixpanel.#{type}(#{arguments.join(', ')});) }.join("\n")
        output = "try {#{output}} catch(err) {}"

        include_script_tag ? "<script type='text/javascript'>#{output}</script>" : output
      end
    end
  end
end

