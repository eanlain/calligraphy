lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'calligraphy/version'

Gem::Specification.new do |s|
  s.name        = 'calligraphy'
  s.version     = Calligraphy::VERSION
  s.summary     = 'WebDAV framework and extension for Rails 5'
  s.description = 'WebDAV framework and extension for Rails 5'
  s.author      = 'Brandon Robins'
  s.email       = 'brandon@onebnottwo.com'
  s.homepage    = 'http://www.github.com/eanlain/calligraphy'
  s.license     = 'MIT'

  s.required_ruby_version = ">= 2.2.2"

  s.files       = Dir['lib/**/*', 'LICENSE', 'README.md']
  s.test_files  = Dir['spec/**/*']

  s.add_dependency 'rails', '~> 5.0'

  s.add_development_dependency 'rspec-rails', '~> 3.7.2'
  s.add_development_dependency 'sqlite3', '~> 1.3.13'
end
