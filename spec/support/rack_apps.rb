def setup_rack_application(application, options = {})
  stub!(:app).and_return(MixpanelMiddleware.new(application.new(options), MIX_PANEL_TOKEN))
end

def html_document
  <<-EOT
    <html>
      <head>
      </head>
      <body>
      </body>
    </html>
  EOT
end

class DummyApp
  def initialize(options)
    @response_with = {}
    @response_with[:status] = options[:status] || "200"
    @response_with[:headers] = options[:headers] || {}
    @response_with[:body] = options[:body] || ""
  end

  def call(env)
    [@response_with[:status], @response_with[:headers], [@response_with[:body]]]
  end
end
