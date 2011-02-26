require "open-uri"
require 'base64'
require 'json'

require 'thread'

class Mixpanel
  def initialize(token, env, async = false)
    @token = token
    @env = env
    @async = async
    clear_queue
  end
  
  # To track events after response with javascript...
  def append_event(js_block = nil, event, properties = {})
    if js_block.nil?
      append_api('track', event, properties)
    else
      queue << [js_block, 'track', [event.to_json, properties.to_json]]
    end
  end
  
  # To execute any javascript API call...
  def append_api(type, *args)
    queue << [type, args.map {|arg| arg.to_json}]
  end
  
  # To track events directly from your backend...
  def track_event(event, properties = {})
    params = build_event(event, properties.merge(:token => @token, :time => Time.now.utc.to_i, :ip => ip))
    parse_response request(params)
  end

  def ip
    @env.has_key?("REMOTE_ADDR") ? @env["REMOTE_ADDR"] : ""
  end

  def queue
    @env["mixpanel_events"]
  end

  def clear_queue
    @env["mixpanel_events"] = []
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
        subprocess  = File.join(File.dirname(__FILE__), 'mixpanel_subprocess.rb')
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
    url = "http://api.mixpanel.com/track/?data=#{data}"

    if(@async)
      w = Mixpanel.worker
      begin
        url << "\n"
        w.write(url)
      rescue Errno::EPIPE => e
        Mixpanel.dispose_worker(w)
      end
    else
      open(url).read
    end
  end

  def build_event(event, properties)
    {:event => event, :properties => properties}
  end
end
