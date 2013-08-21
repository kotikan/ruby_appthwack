# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "ruby_appthwack"

Gem::Specification.new do |s|
  s.name        = "Ruby_AppThwack"
  s.authors     = ["Sam Stewart"]
  s.email       = "sam@playhaven.com"
  s.homepage    = "https://github.com/samstewart/ruby_appthwack"
  s.version     = AppThwack::VERSION
  s.platform    = Gem::Platform::RUBY
  s.summary     = "Ruby AppThwack"
  s.description = "CLI for running UI tests on AppThwack.com"

  s.add_dependency "commander", "~> 4.1"
  s.add_dependency "json", "~> 1.8"
  s.add_dependency "faraday", "~> 0.8"
  s.add_dependency "faraday_middleware", "~> 0.9"
  s.add_dependency "dotenv", "~> 0.7"
  s.add_dependency "shenzhen", "~> 0.4.0"

  s.add_development_dependency "rspec"
  s.add_development_dependency "rake"

  s.files         = Dir["./**/*"].reject { |file| file =~ /\.\/(bin|log|pkg|script|spec|test|vendor)/ }
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
