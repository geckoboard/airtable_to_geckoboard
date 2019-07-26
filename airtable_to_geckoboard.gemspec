# coding: utf-8
require 'airtable_to_geckoboard/version'

Gem::Specification.new do |spec|
  spec.name          = 'airtable_to_geckoboard'
  spec.version       = AirtableToGeckoboard::VERSION
  spec.authors       = ['Megan Leon']
  spec.email         = %w[megan.leon@geckoboard.com]

  spec.summary       = %q{Synchronize Airtable to Geckoboard Datasets API}
  spec.homepage      = 'https://github.com/geckoboard/airtable_to_geckoboard'
  spec.license       = 'MIT'

  spec.required_ruby_version = '>= 2.0'

  spec.files         = Dir['lib/**/*.rb']
  spec.require_paths = %w[lib]

  spec.add_development_dependency 'geckoboard-ruby', '~> 0.4.0'
end