# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)
require 'flexpolyline/version'

Gem::Specification.new do |s|
  s.name        = 'flexpolyline'
  s.version     = FlexPolyline::VERSION
  s.date        = '2022-08-26'
  s.summary     = 'Flexible Polyline encoding: a lossy compressed representation of a list of coordinate pairs or triples.'
  s.description = 'Flexible Polyline encoding: a lossy compressed representation of a list of coordinate pairs or triples.'
  s.authors     = ['HERE Europe B.V.', 'Mònade srl']
  s.files = Dir['lib/**/*']
  s.test_files = Dir['spec/**/*']
  s.required_ruby_version = '>= 2.7.0'
  s.homepage    = 'https://rubygems.org/gems/flexpolyline'
  s.license     = 'MIT'
  s.add_development_dependency 'rspec', '~> 3'
  s.add_development_dependency 'rubocop'
end
