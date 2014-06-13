# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'charazard/version'

Gem::Specification.new do |spec|
  spec.name = 'charazard'
  spec.version = Charazard::VERSION
  spec.authors = ['Jason Weathered']
  spec.email = ['jason@jasoncodes.com']
  spec.summary = %q{Cleans up bad character encodings with liberal application of fire.}
  spec.homepage = 'https://github.com/jasoncodes/charazard'
  spec.license = 'MIT'

  spec.files = `git ls-files -z`.split("\x0")
  spec.executables = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'nokogiri', '~> 1.5'

  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'minitest'
  spec.add_development_dependency 'pry'
end
