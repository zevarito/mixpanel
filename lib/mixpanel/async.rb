module Mixpanel::Async
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
  
  protected
  
  def cmd
    @cmd || begin
      require 'escape'
      require 'rbconfig'
      interpreter = File.join(*RbConfig::CONFIG.values_at("bindir", "ruby_install_name")) + RbConfig::CONFIG["EXEEXT"]
      subprocess = File.join(File.dirname(__FILE__), 'subprocess.rb')
      @cmd = Escape.shell_command([interpreter, subprocess])
    end
  end
    
end