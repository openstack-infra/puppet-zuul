source 'https://rubygems.org'

group :development, :tests do
  gem 'puppetlabs_spec_helper', :require => false
  gem 'rspec-puppet', '~> 2.1.0', :require => false
  gem 'minitest', '~> 4.7', :require => 'minitest/unit'
end

if puppetversion = ENV['PUPPET_GEM_VERSION']
  gem 'puppet', puppetversion, :require => false
else
  gem 'puppet', :require => false
end
