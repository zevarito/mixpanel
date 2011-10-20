module Mixpanel
  class Configuration
    class << self
      attr_writer :logger
    end

    def self.logger
      @logger ||= _default_logger
    end

    def logger
      @logger ||= self.class._default_logger
    end

    def self._default_logger
      logger = defined?(Rails) ? Rails.logger : Logger.new("/dev/null")
      logger.level = Logger::DEBUG
      logger
    end
  end
end
