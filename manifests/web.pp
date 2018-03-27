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
) {

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
    # Minutes, hours, days, etc are not specified here because we are
    # interested in running this *every minute*.
    # This is a mean of backing up status.json periodically in order to provide
    # a mean of restoring lost scheduler queues if need be.
    # We are downloading this file at a location served by the vhost so that we
    # can query it easily should the need arise.
    # If the status.json is unavailable for download, no new files are created.
    if $ssl_cert_file_contents != '' {
      $status = "https://${zuul::vhost_name}/api/status"
    } else {
      $status = "http://${zuul::vhost_name}/api/status"
    }
    cron { 'zuul_scheduler_status_backup':
      user    => 'root',
      command => "timeout -k 5 10 curl ${status} -o /var/lib/zuul/backup/status_$(date +\\%s).json 2>/dev/null",
      require => [Package['curl'],
                  User['zuul'],
                  File['/var/lib/zuul/backup']],
    }
    # Rotate backups and keep no more than 120 files -- or 2 hours worth of
    # backup if Zuul has 100% uptime.
    # We're not basing the rotation on time because the scheduler/web service
    # could be down for an extended period of time.
    # This is ran hourly so technically up to ~3 hours worth of backups will
    # be kept.
    cron { 'zuul_scheduler_status_prune':
      user    => 'root',
      minute  => '0',
      command => 'flock -n /var/run/status_prune.lock ls -dt -1 /var/lib/zuul/backup/* |sed -e "1,120d" |xargs rm -f',
      require => Cron['zuul_scheduler_status_backup'],
    }
  }

  if $ssl_cert_file_contents == '' {
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
      content => $ssl_cert_file_contents,
      require => File['/etc/ssl/certs'],
      before  => Httpd::Vhost[$vhost_name],
    }
    file { "/etc/ssl/private/${vhost_name}.key":
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0600',
      content => $ssl_key_file_contents,
      require => File['/etc/ssl/private'],
      before  => Httpd::Vhost[$vhost_name],
    }
    if $ssl_chain_file_contents != '' {
      file { "/etc/ssl/certs/${vhost_name}_intermediate.pem":
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0644',
        content => $ssl_chain_file_contents,
        require => File['/etc/ssl/certs'],
        before  => Httpd::Vhost[$vhost_name],
      }
    }
  }

  $web_url = "http://${web_listen_address}:${web_listen_port}"
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

  ::httpd::vhost { $vhost_name:
    port       => 80,
    docroot    => $zuul_web_content_root,
    priority   => '50',
    ssl        => true,
    template   => 'zuul/zuulv3.vhost.erb',
    vhost_name => $vhost_name,
  }
  if $ssl {
    ::httpd::vhost { "${vhost_name}-ssl":
      port       => 443,
      docroot    => $zuul_web_content_root,
      priority   => '50',
      ssl        => true,
      template   => 'zuul/zuulv3.vhost.erb',
      vhost_name => $vhost_name,
    }
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
  if !defined(Mod['proxy_wstunnel']) {
    httpd::mod { 'proxy_wstunnel': ensure => present }
  }
  if ! defined(Httpd::Mod['cache_disk']) {
    httpd::mod { 'cache_disk': ensure => present }
  }

}
