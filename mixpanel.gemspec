# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'mixpanel/version'

Gem::Specification.new do |s|
  s.name              = 'mixpanel'
  s.version           = Mixpanel::VERSION
  s.rubyforge_project = 'mixpanel'
  s.description       = 'Simple lib to track events in Mixpanel service. It can be used in any rack based framework.'
  s.authors           = ['Alvaro Gil']
  s.email             = ['zevarito@gmail.com']
  s.homepage          = 'https://github.com/zevarito/mixpanel'
  s.summary           = 'Supports direct request api and javascript requests through a middleware.'

  s.files            = `git ls-files`.split("\n")
  s.require_paths    = ['lib']
  s.extra_rdoc_files = ['README.rdoc']

  s.add_dependency 'json'
  s.add_dependency 'rack'
  s.add_dependency 'escape'

  s.add_development_dependency 'rake'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'ruby-debug19'
  s.add_development_dependency 'rack-test'
  s.add_development_dependency 'fakeweb'
  s.add_development_dependency 'nokogiri'
end
