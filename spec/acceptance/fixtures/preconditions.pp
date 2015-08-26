# Installing ssl-cert in order to get snakeoil certs
package { 'ssl-cert':
  ensure => present,
}

# Installing pip since zuul dependencies are managed by it
package { 'python-setuptools':
  ensure => present,
} -> exec { 'install pip using easy_install':
  command => 'easy_install -U pip',
  path    => '/bin:/usr/bin:/usr/local/bin'
}

# Checking out openstack-infra/project-config
define git_checkout(
  $destination = undef
) {
  Exec { path => '/bin:/usr/bin' }
  exec { "cloning repository ${name} at directory ${destination}":
    command => "git clone ${name} ${destination}",
  }
}

git_checkout { 'git://git.openstack.org/openstack-infra/project-config':
  destination => '/etc/project-config'
}

# Creating ssh rsa keys
define create_temporary_directory() {
  Exec { path => '/bin:/usr/bin' }
  exec { "create temporary ${name} directory":
    command => "mkdir -p ${name}",
  }
}

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
create_temporary_directory { $ssh_key_directory: }
ssh_keygen {'ssh_rsa_key':
  ssh_directory => $ssh_key_directory
}
