require 'beaker-rspec'

hosts.each do |host|

  install_puppet

  on host, "mkdir -p #{host['distmoduledir']}"
end

RSpec.configure do |c|
  # Project root
  proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  # Readable test descriptions
  c.formatter = :documentation

  # Configure all nodes in nodeset
  c.before :suite do
    # Install module and dependencies
    hosts.each do |host|

      # install git, libyaml-dev
      install_package host, 'git'
      install_package host, 'libyaml-dev'

      # install pip (system-config/install_puppet.sh) way
      shell('wget https://bootstrap.pypa.io/get-pip.py')
      shell('python get-pip.py')
      shell('pip install -U setuptools')

      # clean out any module cruft
      shell('rm -fr /etc/puppet/modules/*')

      # install library modules from the forge
      on host, puppet('module','install','puppetlabs-apache', '-v', '0.0.4'), { :acceptable_exit_codes => 0 }
      on host, puppet('module', 'install', 'puppetlabs-stdlib'), { :acceptable_exit_codes => 0 }

      # install puppet modules from git, use master
      shell('git clone https://git.openstack.org/openstack-infra/puppet-vcsrepo /etc/puppet/modules/vcsrepo')
      shell('git clone https://git.openstack.org/openstack-infra/puppet-pip /etc/puppet/modules/pip')
      shell('git clone https://git.openstack.org/openstack-infra/puppet-logrotate /etc/puppet/modules/logrotate')

      # create a fake layout directory
      shell('mkdir -p /tmp/layout')

      # Install the module being tested
      puppet_module_install(:source => proj_root, :module_name => 'zuul')
      # List modules installed to help with debugging
      on hosts[0], puppet('module','list'), { :acceptable_exit_codes => 0 }
    end
  end
end
