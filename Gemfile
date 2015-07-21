# THIS FILE IS MANAGED BY THE PUPPET MODULES SYNC REPO - DO NOT EDIT

source 'https://rubygems.org'

group :development, :test do
  gem 'puppetlabs_spec_helper', :require => false

  gem 'metadata-json-lint'
  # This is nice and all, but let's not worry about it until we've actually
  # got puppet 4.x sorted
  # gem 'puppet-lint-param-docs'
  gem 'puppet-lint-absolute_classname-check'
  gem 'puppet-lint-absolute_template_path'
  gem 'puppet-lint-trailing_newline-check'

  # Puppet 4.x related lint checks
  gem 'puppet-lint-unquoted_string-check'
  gem 'puppet-lint-empty_string-check'
  gem 'puppet-lint-leading_zero-check'
  gem 'puppet-lint-variable_contains_upcase'
  gem 'puppet-lint-numericvariable'
  gem 'puppet-lint-spaceship_operator_without_tag-check'
  gem 'puppet-lint-undef_in_function-check'

  if puppetversion = ENV['PUPPET_GEM_VERSION']
    gem 'puppet', puppetversion, :require => false
  else
    gem 'puppet', '~> 3.0', :require => false
  end

end

# vim:ft=ruby
