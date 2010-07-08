def setup_rack_application(application, options = {})
  stub!(:app).and_return(Middleware.new(application.new(:callback => options.delete(:callback)), MIX_PANEL_TOKEN))
end

class DummyApp
  def initialize(options = {})
    @callback = options.delete(:callback)
  end

  def body
    ""
  end

  def call(env)
    ["200", {}, [body]]
  end
end

class HtmlApp < DummyApp
  def body
    <<-EOT
      <html>
        <head>
        </head>
        <body>
        </body>
      </html>
    EOT
  end

  def call(env)
    ["200", {"Content-Type" => "text/html"}, [body]]
  end
end

class HtmlAppWithEvents < HtmlApp
  def call(env)
    @callback.call(env) if !@callback.nil?

    ["200", {"Content-Type" => "text/html"}, [body]]
  end
end
