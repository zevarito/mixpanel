require 'rack'
require 'json'

module Mixpanel
  class Middleware
    def initialize(app, mixpanel_token, options={})
      @app = app
      @token = mixpanel_token
      @options = {
        :insert_js_last => false,
        :persist => false,
        :config => {}
      }.merge(options)
    end

    def call(env)
      @env = env

      @status, @headers, @response = @app.call(env)
      
      if is_trackable_response?
        merge_queue! if @options[:persist]
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
      return false if @status == 302
      return false if @env.has_key?("Skip-Mixpanel-Middleware")
      is_html_response? || is_javascript_response?
    end

    def render_mixpanel_scripts
      <<-EOT
        <!-- start Mixpanel -->
        <script type="text/javascript">
          (function(d,c){var a,b,g,e;a=d.createElement("script");a.type="text/javascript";
          a.async=!0;a.src=("https:"===d.location.protocol?"https:":"http:")+
          '//api.mixpanel.com/site_media/js/api/mixpanel.2.js';b=d.getElementsByTagName("script")[0];
          b.parentNode.insertBefore(a,b);c._i=[];c.init=function(a,d,f){var b=c;
          "undefined"!==typeof f?b=c[f]=[]:f="mixpanel";g=['disable','track','track_pageview',
          'track_links','track_forms','register','register_once','unregister','identify',
          'name_tag','set_config'];
          for(e=0;e<g.length;e++)(function(a){b[a]=function(){b.push([a].concat(
          Array.prototype.slice.call(arguments,0)))}})(g[e]);c._i.push([a,d,f])};window.mixpanel=c}
          )(document,window.mixpanel||[]);

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
      special_events = ['identify', 'name_tag', 'people.set', 'register']
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
      output = "try {#{output}} catch(err) {}"

      include_script_tag ? "<script type='text/javascript'>#{output}</script>" : output
    end
  end
end

