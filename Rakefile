begin
  require File.expand_path('../.bundle/environment', __FILE__)
rescue LoadError
  require 'rubygems'
  require 'bundler'
  Bundler.setup
end

require 'spec/rake/spectask'

task :default => :spec

desc "Run all examples"
Spec::Rake::SpecTask.new('spec') do |t|
  t.spec_opts = ["-u -c -fs"]
  t.spec_files = FileList['spec/**/*_spec.rb']
end
