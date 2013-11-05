require 'thread'
require "uri"
require "net/http"
require 'json'

module Mixpanel
  class Subprocess
    Q = Queue.new
    ENDMARKER = Object.new

    Thread.abort_on_exception = true
    producer = Thread.new do
      STDIN.each_line() do |data|
        STDERR.puts("Dropped: #{data}") && next if Q.length > 10000
        Q << data
      end
      Q << ENDMARKER
    end

    loop do
      data = Q.pop
      break if(data == ENDMARKER)
      data.chomp!
      data_hash = JSON.load(data)
      if data_hash.is_a?(Hash) && data_hash['_mixpanel_url']
        url = data_hash.delete('_mixpanel_url')
        Net::HTTP.post_form(::URI.parse(url), data_hash)
      end
    end
    producer.join
  end
end
