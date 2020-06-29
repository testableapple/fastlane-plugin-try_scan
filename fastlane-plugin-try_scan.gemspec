# coding: utf-8

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'fastlane/plugin/try_scan/version'

Gem::Specification.new do |spec|
  spec.name          = 'fastlane-plugin-try_scan'
  spec.version       = Fastlane::TryScan::VERSION
  spec.author        = 'Alexey Alter-Pesotskiy'
  spec.email         = 'a.alterpesotskiy@mail.ru'

  spec.summary       = 'The easiest way to retry your fastlane scan action'
  spec.homepage      = "https://github.com/alteral/fastlane-plugin-try_scan"
  spec.license       = "MIT"

  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "https://rubygems.org"
  else
    raise "RubyGems 2.0 or newer is required to protect against public gem pushes."
  end

  spec.files         = Dir["lib/**/*"] + %w(README.md LICENSE)
  spec.require_paths = ['lib']

  spec.add_development_dependency('pry')
  spec.add_development_dependency('bundler')
  spec.add_development_dependency('rake')
  spec.add_development_dependency('fasterer', '0.8.3')
  spec.add_development_dependency('rubocop', '0.49.1')
  spec.add_development_dependency('rubocop-require_tools')
  spec.add_development_dependency('simplecov')
  spec.add_development_dependency('fastlane', '>= 2.144.0')
end
