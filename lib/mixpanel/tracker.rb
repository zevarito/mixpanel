require "open-uri"
require 'base64'
require 'json'
require 'thread'
require 'mixpanel/tracker/middleware'

module Mixpanel
  class Tracker
    
    MIXPANEL_API_URL  = 'http://api.mixpanel.com'.freeze
    TRACK_ENDPOINT    = '/track/?data='.freeze
    ENGAGE_ENDPOINT   = '/engage/?data='.freeze
    IMPORT_ENDPOINT   = '/import/?data='.freeze
    
    PERSON_PROPERTIES = %w(email first_name last_name created last_login username country_code).freeze
    
    def initialize(token, env, options = {})
      @token    = token
      @api_key  = options.fetch(:api_key, "")
      @env      = env
      @async    = options.fetch(:async, false)
      @import   = options.fetch(:import, false)
      @url      = options.fetch(:url, MIXPANEL_API_URL)
      @persist  = options.fetch(:persist, false)

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
      append_api('people.set', person_properties(properties))
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
      parse_response request(:track,
        :event      => event,
        :properties => options.merge(properties)
      )
    end
    
    def engage(action, distinct_id, properties = {})
      options = { }
      options.merge!( :$token => @token ) if @token
      parse_response request(:engage, options.merge(
        :$distinct_id       => distinct_id, 
        "$#{action}".to_sym => person_properties(properties)
      ))
    end
    
    def engage_set(distinct_id, properties = {})
      engage(:set, distinct_id, properties)
    end
    
    def engage_add(distinct_id, properties = {})
      engage(:add, distinct_id, properties)
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

    class << self
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
    
    def person_properties(properties = {})
      properties.inject({}) do |out, (k, v)|
        if PERSON_PROPERTIES.member?(k.to_s)
          out["$#{k}".to_sym] = v
        else
          out[k] = v
        end
        out
      end
    end

    def parse_response(response)
      response == "1" ? true : false
    end

    def request(mode, params)
      data = Base64.encode64(JSON.generate(params)).gsub(/\n/,'')
      
      mode = :import if @import
      endpoint = case mode
        when :track   then TRACK_ENDPOINT
        when :engage  then ENGAGE_ENDPOINT
        when :import  then IMPORT_ENDPOINT
      end
      url = "#{@url}#{endpoint}#{data}"
      url += "&api_key=#{@api_key}" if mode == :import
      
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
  end
end
