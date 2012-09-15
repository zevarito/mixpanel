require "open-uri"
require 'base64'
require 'json'
require 'thread'
require 'mixpanel/tracker/middleware'

module Mixpanel
  class Tracker
    def initialize(token, env, options={})
      @token = token
      @api_key = options.fetch(:api_key, "")
      @env = env
      @async = options.fetch(:async, false)
      @import = options.fetch(:import, false)
      @url = @import ? 'http://api.mixpanel.com/import/?data' : options.fetch(:url, 'http://api.mixpanel.com/track/?data=')
      @persist = options.fetch(:persist, false)

      if @persist
        @env["rack.session"]["mixpanel_events"] ||= []
      else
        clear_queue
      end
    end

    def append_event(event, properties = {})
      append_api('track', event, properties)
    end

    def append_person_event(properties = {})
      # evaluate symbols and rewrite
      special_properties = %w{email created first_name last_name last_login username country_code}
      special_properties.each do |key|
        symbolized_key = key.to_sym
        if properties.has_key?(symbolized_key)
          properties["$#{key}"] = properties[symbolized_key]
          properties.delete(symbolized_key)
        end
      end
      append_api('people.set', properties)
    end

    def append_person_increment_event(property, increment=1)
      append_api('people.increment', property, increment)
    end

    def append_api(type, *args)
      queue << [type, args.map {|arg| arg.to_json}]
    end

    def track_event(event, properties = {})
      options = { :time => Time.now.utc.to_i, :ip => ip }
      options.merge!( :token => @token ) if @token
      options.merge!(properties)
      params = build_event(event, options)
      parse_response request(params)
    end

    def ip
      if @env.has_key?("HTTP_X_FORWARDED_FOR")
        @env["HTTP_X_FORWARDED_FOR"].split(",").last
      elsif @env.has_key?("REMOTE_ADDR")
        @env["REMOTE_ADDR"]
      else
        ""
      end
    end

    def queue
      if @persist
        return @env["rack.session"]["mixpanel_events"]
      else
        return @env["mixpanel_events"]
      end
    end

    def clear_queue
      if @persist
        @env["rack.session"]["mixpanel_events"] = []
      else
        @env["mixpanel_events"] = []
      end
    end

    class <<self
      WORKER_MUTEX = Mutex.new

      def worker
        WORKER_MUTEX.synchronize do
          @worker || (@worker = IO.popen(self.cmd, 'w'))
        end
      end

      def dispose_worker(w)
        WORKER_MUTEX.synchronize do
          if(@worker == w)
            @worker = nil
            w.close
          end
        end
      end

      def cmd
        @cmd || begin
          require 'escape'
          require 'rbconfig'
          interpreter = File.join(*RbConfig::CONFIG.values_at("bindir", "ruby_install_name")) + RbConfig::CONFIG["EXEEXT"]
          subprocess  = File.join(File.dirname(__FILE__), 'tracker/subprocess.rb')
          @cmd = Escape.shell_command([interpreter, subprocess])
        end
      end
    end

    private

    def parse_response(response)
      response == "1" ? true : false
    end

    def request(params)
      data = Base64.encode64(JSON.generate(params)).gsub(/\n/,'')
      url = @import ? @url + "=" + data + '&api_key=' + @api_key : @url + data

      if(@async)
        w = Tracker.worker
        begin
          url << "\n"
          w.write(url)
        rescue Errno::EPIPE => e
          Tracker.dispose_worker(w)
        end
      else
        open(url).read
      end
    end

    def build_event(event, properties)
      {:event => event, :properties => properties}
    end
  end
end
