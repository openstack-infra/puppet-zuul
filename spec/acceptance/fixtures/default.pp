class { '::zuul':
  zuul_ssh_private_key         => file('/tmp/zuul-ssh-keys/ssh_rsa_key'),
  zuulv3                       => true,
  python_version               => 3,
}

class { '::zuul::scheduler':
  layout_dir     => '/etc/project-config/zuul',
  python_version => 3,
  use_mysql      => true,
}

class { '::zuul::merger': }
class { '::zuul::executor': }
class { '::zuul::web':
  tenant_name            => 'openstack',
  ssl_cert_file_contents => file('/etc/ssl/certs/ssl-cert-snakeoil.pem'),
  ssl_key_file_contents  => file('/etc/ssl/private/ssl-cert-snakeoil.key'),
}

class { '::zuul::fingergw': }

class { '::zuul::known_hosts':
  known_hosts_content => 'known_hosts_content',
}
