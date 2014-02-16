require 'uri'
require 'net/http'

module Mixpanel
  module Http
    class Client
      def self.post url, data
        uri = URI(url)
        req = Net::HTTP::Post.new(uri.request_uri)
        req.form_data = data
        req.basic_auth uri.user, uri.password if uri.user
        ssl = uri.scheme == 'https' 

        Net::HTTP.start(uri.host, uri.port, :use_ssl => ssl) do |http|
          http.request(req)
        end
      end
    end

    def http_client
      Client
    end
  end
end
