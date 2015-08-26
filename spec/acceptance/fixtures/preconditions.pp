# Installing ssl-cert in order to get snakeoil certs
package { 'ssl-cert':
  ensure => present,
}

# workaround since pip is not being installed as part of this module
exec { 'download get-pip.py':
  command => 'wget https://bootstrap.pypa.io/get-pip.py -O /tmp/get-pip.py',
  path    => '/bin:/usr/bin:/usr/local/bin',
  creates => '/tmp/get-pip.py',
}

exec { 'install pip using get-pip':
  command     => 'python /tmp/get-pip.py',
  path        => '/bin:/usr/bin:/usr/local/bin',
  refreshonly => true,
  subscribe   => Exec['download get-pip.py'],
}

vcsrepo { '/etc/project-config':
  ensure   => latest,
  provider => git,
  revision => 'master',
  source   => 'git://git.openstack.org/openstack-infra/project-config',
}

# Creating ssh rsa keys
define ssh_keygen (
  $ssh_directory = undef
) {
  Exec { path => '/bin:/usr/bin' }

  $ssh_key_file = "${ssh_directory}/${name}"

  exec { "ssh-keygen for ${name}":
    command => "ssh-keygen -t rsa -f ${ssh_key_file} -N ''",
    creates => $ssh_key_file,
  }
}

$ssh_key_directory = '/tmp/zuul-ssh-keys'
file { $ssh_key_directory:
  ensure => directory
}
ssh_keygen {'ssh_rsa_key':
  ssh_directory => $ssh_key_directory,
  require       => File[$ssh_key_directory],
}
