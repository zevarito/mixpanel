spec = Gem::Specification.new do |s|
  s.name = "mixpanel"
  s.version = "0.5"
  s.rubyforge_project = "mixpanel"
  s.description = "Simple lib to track events in Mixpanel service."
  s.author = "Alvaro Gil"
  s.email = "zevarito@gmail.com"
  s.homepage = "http://cuboxsa.com"
  s.platform = Gem::Platform::RUBY
  s.summary = "Supports direct request api and javascript requests."
  s.files = %w[
    .gitignore
    README
    LICENSE
    Rakefile
    mixpanel.gemspec
    lib/mixpanel.rb
    spec/spec_helper.rb
    spec/mixpanel/mixpanel_spec.rb
  ]
  s.require_path = "lib"
  s.has_rdoc = false
  s.extra_rdoc_files = ["README"]
  s.add_dependency 'json'
  s.add_development_dependency 'rspec'
  s.add_development_dependency 'fakeweb'
end
