# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "active_model_base/version"

Gem::Specification.new do |s|
  s.name        = "ActiveModelBase"
  s.version     = ActiveModel::Base::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Frank Hall"]
  s.email       = ["ChapterHouse.Dune@gmail.com"]
  s.homepage    = ""
  s.summary     = %q{A base class for active model that is analogous to ActiveRecord::Base}
  s.description = %q{A base class for active model that is analogous to ActiveRecord::Base. It provides attributes, finders, serializers, and associations}

  s.rubyforge_project = "ActiveModelBase"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency 'activesupport', '~> 3.0.0'
  s.add_dependency 'activemodel', '~> 3.0.0'
  s.add_dependency 'uuid'
  s.add_development_dependency 'rspec'
end
