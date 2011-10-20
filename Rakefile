require 'rubygems'
require 'rspec/core/rake_task'

task :default => :spec

desc "Run all examples"
RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = ["-c -fs"]
  t.pattern = 'spec/**/*_spec.rb'
end
