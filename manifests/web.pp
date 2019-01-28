# Copyright 2017 Red Hat, Inc.
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

# == Class: zuul::web
#
class zuul::web (
  $ensure = undef,
  $manage_log_conf = true,
  $web_listen_address = '127.0.0.1',
  $web_listen_port = 9000,
  $enable_status_backups = true,
  $tenant_name = '',
  $vhost_name = $::fqdn,
  $ssl_cert_file_contents = '',
  $ssl_key_file_contents = '',
  $ssl_chain_file_contents = '',
  $block_referers = [],
  $serveradmin = "webmaster@${::fqdn}",
  # New sets of hashes on which create resources will be run.
  # If not supplied the legacy parameters above will be used to
  # construct these hashes.
  $vhosts = {},
  $vhosts_flags = {},
  $vhosts_ssl = {},
) {

  #TODO create_resources
  if $vhosts == {} {
    if $ssl_cert_file_contents == '' {
      $vhost_port = 80
      $use_ssl = false
      $vhosts_ssl_int = {}
    } else {
      $vhost_port = 443
      $use_ssl = true
      $vhosts_ssl_int = {
        "${vhost_name}" => {
          ssl_cert_file_contents  => $ssl_cert_file_contents,
          ssl_key_file_contents   => $ssl_key_file_contents,
          ssl_chain_file_contents => $ssl_chain_file_contents,
        }
      }
    }}
    $vhosts_int = {
      "${vhost_name}" => {
        port       => $vhost_port,
        docroot    => $zuul_web_content_root,
        priority   => '50',
        ssl        => $use_ssl,
        template   => 'zuul/zuulv3.vhost.erb',
        vhost_name => $vhost_name,
      }
    }
    $vhosts_flags_int = {
      "${vhost_name}" => {
        tenant_name => $tenant_name,
        ssl         => $use_ssl,
      }
    }
  }
  else {
    $vhosts_ssl_int = $vhosts_ssl
    $vhosts_int = $vhosts
    $vhosts_flags_int = $vhosts_flags
  }

  service { 'zuul-web':
    ensure     => $ensure,
    name       => 'zuul-web',
    enable     => true,
    hasrestart => true,
    require    => [File['/etc/init.d/zuul-web'],
                  File['/etc/default/zuul-web'],
                  Class['zuul::systemd_reload']]
  }

  file { '/etc/init.d/zuul-web':
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0555',
    source => 'puppet:///modules/zuul/zuul-web.init',
    notify => Class['zuul::systemd_reload'],
  }

  if $manage_log_conf {
    file { '/etc/zuul/web-logging.conf':
      ensure => present,
      source => 'puppet:///modules/zuul/web-logging.conf',
    }
  }

  include ::logrotate
  ::logrotate::file { 'web.log':
    log     => '/var/log/zuul/web.log',
    options => [
      'compress',
      'missingok',
      'rotate 30',
      'daily',
      'notifempty',
    ],
    require => Service['zuul-web'],
  }
  ::logrotate::file { 'web-debug.log':
    log     => '/var/log/zuul/web-debug.log',
    options => [
      'compress',
      'missingok',
      'rotate 30',
      'daily',
      'notifempty',
    ],
    require => Service['zuul-web'],
  }

  file { '/etc/default/zuul-web':
    ensure  => present,
    mode    => '0444',
    content => "PIDFILE=/var/run/zuul/web.pid\n",
  }

  if !defined(Package['curl']) {
    package { 'curl':
      ensure => present
    }
  }

  file { '/var/lib/zuul/backup':
    ensure  => directory,
    require => File['/var/lib/zuul'],
  }

  if $enable_status_backups {
    create_resources(zuul::status_backups, $vhosts_flags_int)
  }

  $web_url = "http://${web_listen_address}:${web_listen_port}"
  $websocket_url = "ws://${web_listen_address}:${web_listen_port}"
  $zuul_web_root = '/opt/zuul-web'
  $zuul_web_content_root = '/opt/zuul-web/content'
  $zuul_web_src_root = '/opt/zuul-web/source'
  $zuul_web_filename = 'zuul-content-latest.tar.gz'
  $zuul_web_url = "http://tarballs.openstack.org/zuul/${zuul_web_filename}"

  file { $zuul_web_root:
    ensure  => directory,
    group   => 'zuul',
    mode    => '0755',
    owner   => 'zuul',
    require => User['zuul'],
  }

  file { $zuul_web_content_root:
    ensure  => directory,
    group   => 'zuul',
    mode    => '0755',
    owner   => 'zuul',
    require => [
      File[$zuul_web_root],
      User['zuul'],
    ]
  }

  file { $zuul_web_src_root:
    ensure  => directory,
    group   => 'zuul',
    mode    => '0755',
    owner   => 'zuul',
    require => [
      File[$zuul_web_root],
      User['zuul'],
    ]
  }

  # Download the latest zuul-web
  exec { 'get-zuul-web':
    command => "curl ${zuul_web_url} -z ./${zuul_web_filename} -o ${zuul_web_filename}",
    path    => '/bin:/usr/bin',
    cwd     => $zuul_web_root,
    require => [
      File[$zuul_web_root],
      File[$zuul_web_content_root],
      File[$zuul_web_src_root],
    ],
    onlyif  => "curl -I ${zuul_web_url} -z ./${zuul_web_filename} | grep '200 OK'",
  }

  # Unpack storyboard-zuul_web
  exec { 'unpack-zuul-web':
    command     => "rm -rf ${zuul_web_src_root}/* && tar -C ${zuul_web_src_root} -xzf ./${zuul_web_filename}",
    path        => '/bin:/usr/bin',
    refreshonly => true,
    cwd         => $zuul_web_root,
    require     => Exec['get-zuul-web'],
    subscribe   => Exec['get-zuul-web'],
  }

  # Sync zuul-web to the directory we serve it from. This is so that we don't
  # have files go missing - but also so that we can clean up old verisons of
  # files. The assets built by webpack have hashes in the filenames to help
  # with caching.
  exec { 'sync-zuul-web':
    command     => "rsync -rl --delete-delay . ${zuul_web_content_root}/",
    path        => '/bin:/usr/bin',
    refreshonly => true,
    cwd         => $zuul_web_src_root,
    require     => Exec['unpack-zuul-web'],
    subscribe   => Exec['unpack-zuul-web'],
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
  if !defined(Httpd::Mod['proxy_wstunnel']) {
    httpd::mod { 'proxy_wstunnel': ensure => present }
  }
  if ! defined(Httpd::Mod['cache_disk']) {
    httpd::mod { 'cache_disk': ensure => present }
  }

  if $vhosts_ssl_int != {} {
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
    create_resources(zuul::ssl_files, $vhosts_ssl_int)
  }
  create_resources(httpd::vhost, $vhosts_int)
}
