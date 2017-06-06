# Copyright 2012-2013 Hewlett-Packard Development Company, L.P.
# Copyright 2012 Antoine "hashar" Musso
# Copyright 2012 Wikimedia Foundation Inc.
# Copyright 2013 OpenStack Foundation
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

# == Class: zuul
#
class zuul (
  $vhost_name = $::fqdn,
  $serveradmin = "webmaster@${::fqdn}",
  $proxy_ssl_cert_file_contents = '',
  $proxy_ssl_key_file_contents = '',
  $proxy_ssl_chain_file_contents = '',
  $block_referers = [],
) {
  include ::httpd

  file { '/var/lib/zuul/www':
    ensure  => directory,
    require => File['/var/lib/zuul'],
  }

  file { '/var/lib/zuul/www/lib':
    ensure  => directory,
    require => File['/var/lib/zuul/www'],
  }

  package { 'libjs-jquery':
    ensure => present,
  }

  file { '/var/lib/zuul/www/jquery.min.js':
    ensure => absent
  }

  file { '/var/lib/zuul/www/lib/jquery.min.js':
    ensure  => link,
    target  => '/usr/share/javascript/jquery/jquery.min.js',
    require => [File['/var/lib/zuul/www/lib'],
                Package['libjs-jquery']],
  }

  vcsrepo { '/opt/twitter-bootstrap':
    ensure   => latest,
    provider => git,
    revision => 'v3.1.1',
    source   => 'https://github.com/twbs/bootstrap.git',
  }

  file { '/var/lib/zuul/www/bootstrap':
    ensure => absent
  }

  file { '/var/lib/zuul/www/lib/bootstrap':
    ensure  => link,
    target  => '/opt/twitter-bootstrap/dist',
    require => [File['/var/lib/zuul/www/lib'],
                Package['libjs-jquery'],
                Vcsrepo['/opt/twitter-bootstrap']],
  }

  vcsrepo { '/opt/jquery-visibility':
    ensure   => latest,
    provider => git,
    revision => 'master',
    source   => 'https://github.com/mathiasbynens/jquery-visibility.git',
  }

  file { '/var/lib/zuul/www/jquery-visibility.min.js':
    ensure => absent
  }

  exec { 'install-jquery-visibility':
    command     => 'yui-compressor -o /var/lib/zuul/www/lib/jquery-visibility.js /opt/jquery-visibility/jquery-visibility.js',
    path        => 'bin:/usr/bin',
    refreshonly => true,
    subscribe   => Vcsrepo['/opt/jquery-visibility'],
    require     => [File['/var/lib/zuul/www/lib'],
                    Package['yui-compressor'],
                    Vcsrepo['/opt/jquery-visibility']],
  }

  vcsrepo { '/opt/graphitejs':
    ensure   => latest,
    provider => git,
    revision => 'master',
    source   => 'https://github.com/prestontimmons/graphitejs.git',
  }

  file { '/var/lib/zuul/www/jquery.graphite.js':
    ensure => absent
  }

  file { '/var/lib/zuul/www/lib/jquery.graphite.js':
    ensure  => link,
    target  => '/opt/graphitejs/jquery.graphite.js',
    require => [File['/var/lib/zuul/www/lib'],
                Vcsrepo['/opt/graphitejs']],
  }

  file { '/var/lib/zuul/www/index.html':
    ensure  => link,
    target  => '/opt/zuul/etc/status/public_html/index.html',
    require => File['/var/lib/zuul/www'],
  }

  file { '/var/lib/zuul/www/styles':
    ensure  => link,
    target  => '/opt/zuul/etc/status/public_html/styles',
    require => File['/var/lib/zuul/www'],
  }

  file { '/var/lib/zuul/www/zuul.app.js':
    ensure  => link,
    target  => '/opt/zuul/etc/status/public_html/zuul.app.js',
    require => File['/var/lib/zuul/www'],
  }

  file { '/var/lib/zuul/www/jquery.zuul.js':
    ensure  => link,
    target  => '/opt/zuul/etc/status/public_html/jquery.zuul.js',
    require => File['/var/lib/zuul/www'],
  }

  file { '/var/lib/zuul/www/images':
    ensure  => link,
    target  => '/opt/zuul/etc/status/public_html/images',
    require => File['/var/lib/zuul/www'],
  }

  if $proxy_ssl_cert_file_contents == '' {
    $ssl = false
  } else {
    $ssl = true
    file { '/etc/ssl/certs':
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0755',
    }
    file { '/etc/ssl/private':
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0700',
    }
    file { "/etc/ssl/certs/${vhost_name}.pem":
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => $proxy_ssl_cert_file_contents,
      require => File['/etc/ssl/certs'],
      before  => Httpd::Vhost[$vhost_name],
    }
    file { "/etc/ssl/private/${vhost_name}.key":
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0600',
      content => $proxy_ssl_key_file_contents,
      require => File['/etc/ssl/private'],
      before  => Httpd::Vhost[$vhost_name],
    }
    if $proxy_ssl_chain_file_contents != '' {
      file { "/etc/ssl/certs/${vhost_name}_intermediate.pem":
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => $proxy_ssl_chain_file_contents,
        require => File['/etc/ssl/certs'],
        before  => Httpd::Vhost[$vhost_name],
      }
    }
  }

  ::httpd::vhost { $vhost_name:
    port       => 443, # Is required despite not being used.
    docroot    => 'MEANINGLESS ARGUMENT',
    priority   => '50',
    ssl        => $ssl,
    template   => 'zuul/zuul.vhost.erb',
    vhost_name => $vhost_name,
  }
  if ! defined(Httpd::Mod['rewrite']) {
    httpd::mod { 'rewrite': ensure => present }
  }
  if ! defined(Httpd::Mod['proxy']) {
    httpd::mod { 'proxy': ensure => present }
  }
  if ! defined(Httpd::Mod['proxy_http']) {
    httpd::mod { 'proxy_http': ensure => present }
  }
  if ! defined(Httpd::Mod['cache']) {
    httpd::mod { 'cache': ensure => present }
  }
  if ! defined(Httpd::Mod['cgid']) {
    httpd::mod { 'cgid': ensure => present }
  }

  case $::lsbdistcodename {
    'precise': {
      if ! defined(Httpd::Mod['mem_cache']) {
        httpd::mod { 'mem_cache': ensure => present }
      }
      if ! defined(Httpd::Mod['version']) {
        httpd::mod { 'version': ensure => present }
      }
    }
    default: {
      if ! defined(Httpd::Mod['cache_disk']) {
        httpd::mod { 'cache_disk': ensure => present }
      }
    }
  }
}
