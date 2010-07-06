def setup_rack_application(application)
  stub!(:app).and_return(Middleware.new(application.new, MIX_PANEL_TOKEN))
end

class HtmlApp
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

class DummyApp
  def body
    ""
  end

  def call(env)
    ["200", {}, [body]]
  end
end
