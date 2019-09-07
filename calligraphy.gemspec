# frozen_string_literal: true

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'calligraphy/version'

Gem::Specification.new do |s|
  s.name        = 'calligraphy'
  s.version     = Calligraphy::VERSION
  s.summary     = 'WebDAV framework and extension for Rails'
  s.author      = 'Brandon Robins'
  s.email       = 'brandon@onebnottwo.com'
  s.homepage    = 'http://www.github.com/eanlain/calligraphy'
  s.license     = 'MIT'

  s.required_ruby_version = '>= 2.5.0'

  s.files = Dir['lib/**/*', 'LICENSE', 'README.md']

  s.add_dependency 'rails', '>= 5.1.6.2'

  s.add_development_dependency 'puma', '~> 4.1.0'
  s.add_development_dependency 'rake', '~> 12.3.3'
  s.add_development_dependency 'rspec-rails', '~> 3.7.2'
  s.add_development_dependency 'rubocop', '~> 0.74.0'
  s.add_development_dependency 'sqlite3', '~> 1.4.1'
end
