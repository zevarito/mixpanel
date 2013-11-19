files = ['README.md', 'LICENSE', 'Rakefile', 'mixpanel.gemspec', '{spec,lib}/**/*'].map {|f| Dir[f]}.flatten

spec = Gem::Specification.new do |s|
  s.name = "mixpanel"
  s.license = "MIT"
  s.version = "4.1.1"
  s.rubyforge_project = "mixpanel"
  s.description = "Simple lib to track events in Mixpanel service. It can be used in any rack based framework."
  s.author = "Alvaro Gil"
  s.email = "zevarito@gmail.com"
  s.homepage = "http://github.com/zevarito/mixpanel"
  s.platform = Gem::Platform::RUBY
  s.summary = "Supports direct request api and javascript requests through a middleware."
  s.files = files
  s.require_path = "lib"
  s.has_rdoc = false
  s.extra_rdoc_files = ["README.md"]
  s.add_dependency 'json'
  s.add_dependency 'rack'
  s.add_dependency 'escape'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'rack-test'
  s.add_development_dependency 'fakeweb'
  s.add_development_dependency 'nokogiri'
  s.add_development_dependency 'rake'
end
