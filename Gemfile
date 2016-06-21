source 'https://rubygems.org'

group :development, :test, :system_tests do
  gem 'puppet-openstack_spec_helper',
      :git     => 'https://git.openstack.org/openstack-infra/puppet-openstack_infra_spec_helper',
      :require => false
  # Not all modules can do this, so we add it here to the ones that can
  gem 'puppet-lint-empty_string-check'
end

# vim:ft=ruby
