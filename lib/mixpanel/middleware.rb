require 'rack'

class Middleware
  def initialize(app, mixpanel_token)
    @app = app
    @token = mixpanel_token
  end

  def call(env)
    @env = env

    @status, @headers, @response = @app.call(env)

    build_response!
    update_content_length!

    [@status, @headers, @response]
  end

  private

  def build_response!
    @response.each do |part|
      if is_html?
        part.gsub!("</head>", "#{render_mixpanel_scripts}</head>") if !is_ajax?
        part.gsub!("</head>", "#{render_event_tracking_scripts}</head>")
      end
    end
  end

  def update_content_length!
    @headers.merge!("Content-Length" => @response.join("").length.to_s)
  end

  def is_ajax?
    @env.has_key?("HTTP_X_REQUESTED_WITH") && @env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
  end

  def is_html?
    @headers["Content-Type"].include?("text/html") if @headers.has_key?("Content-Type")
  end

  def render_mixpanel_scripts
    <<-EOT
      <script type='text/javascript'>
        var mp_protocol = (('https:' == document.location.protocol) ? 'https://' : 'http://');
        document.write(unescape('%3Cscript src="' + mp_protocol + 'api.mixpanel.com/site_media/js/api/mixpanel.js" type="text/javascript"%3E%3C/script%3E'));
      </script>
      <script type='text/javascript'>
        try {
          var mpmetrics = new MixpanelLib('#{@token}');
        } catch(err) {
          null_fn = function () {};
          var mpmetrics = {
            track: null_fn,  track_funnel: null_fn,  register: null_fn,  register_once: null_fn, register_funnel: null_fn
          };
        }
      </script>
    EOT
  end

  def queue
    return [] if !@env.has_key?('mixpanel_events') || @env['mixpanel_events'].empty?
    @env['mixpanel_events']
  end

  def render_event_tracking_scripts
    return "" if queue.empty?

    <<-EOT
      <script type='text/javascript'>
        #{queue.map {|event| %(mpmetrics.track("#{event[:event]}", #{event[:properties].to_json});) }.join("\n")}
      </script>
    EOT
  end
end