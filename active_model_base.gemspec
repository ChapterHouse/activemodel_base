# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'activemodel_base/version'

Gem::Specification.new do |spec|
  spec.name          = 'activemodel_base'
  spec.version       = ActiveModel::Base::VERSION
  spec.authors       = ['Frank Hall']
  spec.email         = ['ChapterHouse.Dune@gmail.com']
  spec.description   = %q{A base class for active model that is analogous to ActiveRecord::Base}
  spec.summary       = %q{A base class for active model that is analogous to ActiveRecord::Base. It provides attributes, finders, serializers, and associations}
  spec.homepage      = 'https://github.com/ChapterHouse/activemodel_base.git'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '~> 2.13'
  spec.add_development_dependency 'rdoc'

  spec.add_dependency 'activesupport', '~> 3.0.0'
  spec.add_dependency 'activemodel', '~> 3.0.0'
  spec.add_dependency 'uuid'

end
