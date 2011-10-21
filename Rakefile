begin
  require 'rspec/core/rake_task'
rescue LoadError => e
  puts "RSpec not loaded - make sure it's installed and you're using bundle exec"
  exit 1
end

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

