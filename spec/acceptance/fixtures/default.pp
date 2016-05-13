class { '::zuul':
  proxy_ssl_cert_file_contents => file('/etc/ssl/certs/ssl-cert-snakeoil.pem'),
  proxy_ssl_key_file_contents  => file('/etc/ssl/private/ssl-cert-snakeoil.key'),
  zuul_ssh_private_key         => file('/tmp/zuul-ssh-keys/ssh_rsa_key'),
}

class { '::zuul::server':
  layout_dir => '/etc/project-config/zuul'
}

class { '::zuul::merger': }
class { '::zuul::launcher': }
class { '::zuul::known_hosts':
  known_hosts_content => 'known_hosts_content',
}
