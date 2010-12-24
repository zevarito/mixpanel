
require 'rubygems'
require 'mixpanel'
require 'open-uri'

require 'thread'

class Mixpanel::Subprocess
  Q = Queue.new
  ENDMARKER = Object.new

  Thread.abort_on_exception = true
  producer = Thread.new do 
    STDIN.each_line() do |url|
      STDERR.puts("Dropped: #{url}") && next if Q.length > 10000
      Q << url
    end
    Q << ENDMARKER
  end

  loop do
    url = Q.pop
    break if(url == ENDMARKER)
    url.chomp!
    next if(url.empty?) #for testing
  
    open(url).read
  end
  producer.join
end