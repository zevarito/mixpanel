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
      @action = options.fetch(:action, :event)
      raise unless [:import, :event, :person].include?(@action)
      
      @url = case @action
      when :import then 'http://api.mixpanel.com/import/?data'
      when :person then 'http://api.mixpanel.com/engage/?data='
      when :event then options.fetch(:url, 'http://api.mixpanel.com/track/?data=')
      end
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
    
    def update_person(id, action, properties={})
      params = build_person(id, action, properties)
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
      url = if @action == :import
        @url + "=" + data + '&api_key=' + @api_key
      else
        @url + data
      end

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
      raise if @action == :person
      {:event => event, :properties => properties}
    end
    
    def build_person(id, action, params)
      raise unless @action == :person
      raise unless [:set, :add].include?(action)
      { "$#{action}" => params, '$token' => @token, '$distinct_id' => id }
    end
  end
end
