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
  $gearman_server = '127.0.0.1',
  $gearman_check_job_registration = true,
  $internal_gearman = true,
  $gerrit_server = '',
  $gerrit_user = '',
  $gerrit_baseurl = '',
  $gerrit_strip_branch_ref = '',
  $zuul_ssh_private_key = '',
  $layout_file_name = 'layout.yaml',
  $zookeeper_hosts = '127.0.0.1:2181',
  $zookeeper_session_timeout = undef,
  $tenant_file_name = 'main.yaml',
  $url_pattern = '',
  $status_url = "https://${::fqdn}/",
  $zuul_status_url = 'http://127.0.0.1:8001',
  $zuul_url = '',
  $git_source_repo = 'https://git.openstack.org/openstack-infra/zuul',
  $job_name_in_report = false,
  $revision = 'master',
  $statsd_host = '',
  $git_email = '',
  $git_name = '',
  $smtp_host = 'localhost',
  $smtp_port = 25,
  $smtp_default_from = "zuul@${::fqdn}",
  $smtp_default_to = "zuul.reports@${::fqdn}",
  $swift_account_temp_key = '',
  $swift_authurl = '',
  $swift_auth_version = '',
  $swift_user = '',
  $swift_key = '',
  $swift_tenant_name = '',
  $swift_region_name = '',
  $swift_default_container = '',
  $swift_default_logserver_prefix = '',
  $swift_default_expiry = 7200,
  $proxy_ssl_cert_file_contents = '',
  $proxy_ssl_key_file_contents = '',
  $proxy_ssl_chain_file_contents = '',
  $block_referers = [],
  # Launcher config
  $accept_nodes = '',
  $jenkins_jobs = '',
  $workspace_root = '',
  $worker_private_key_file = '',
  $worker_username = '',
  $sites = [],
  $nodes = [],
  $connections = [],
  $connection_secrets = [],
  $trusted_ro_dirs = [],
  $trusted_rw_dirs = [],
  $untrusted_ro_dirs = [],
  $untrusted_rw_dirs = [],
  $trusted_ro_paths = [],
  $trusted_rw_paths = [],
  $untrusted_ro_paths = [],
  $untrusted_rw_paths = [],
  $disk_limit_per_job = '',
  $python_version = 2,
  $zuulv3 = false,
  $gearman_client_ssl_cert = undef,
  $gearman_client_ssl_key = undef,
  $gearman_server_ssl_cert = undef,
  $gearman_server_ssl_key = undef,
  $gearman_ssl_ca = undef,
  $zuul_web_url = 'http://127.0.0.1:9000',
  $zuul_scheduler_url = 'http://127.0.0.1:8001',
  $site_variables_yaml_file = undef,
  $zuul_tenant_name = undef,
) {
  include ::httpd
  include ::pip

  include ::zuul::systemd_reload

  if ($python_version == 3) {
    include ::pip::python3
    $pip_provider = pip3
    $pip_command = 'pip3'
  } else {
    $pip_provider = openstack_pip
    $pip_command = 'pip'
  }

  $packages = [
    'libffi-dev',
    'libssl-dev',
  ]

  package { $packages:
    ensure => present,
  }

  # yappi, pyzmq requires this to build
  if ! defined(Package['build-essential']) {
    package { 'build-essential':
      ensure => present,
    }
  }

  package { 'yappi':
    ensure   => present,
    provider => $pip_provider,
    require  => Class['pip'],
  }

  if ! $zuulv3 {
    # needed by python-keystoneclient, has system bindings
    # Zuul and Nodepool both need it, so make it conditional
    if ! defined(Package['python-lxml']) {
      package { 'python-lxml':
        ensure => present,
      }
    }

    # A lot of things need yaml, be conservative requiring this package to avoid
    # conflicts with other modules.
    if ! defined(Package['python-yaml']) {
      package { 'python-yaml':
        ensure => present,
      }
    }

    if ! defined(Package['python-paramiko']) {
      package { 'python-paramiko':
        ensure   => present,
      }
    }

    if ! defined(Package['python-daemon']) {
      package { 'python-daemon':
        ensure => present,
      }
    }

    if ! defined(Package['yui-compressor']) {
      package { 'yui-compressor':
        ensure => present,
      }
    }
  }

  user { 'zuul':
    ensure     => present,
    home       => '/home/zuul',
    shell      => '/bin/bash',
    gid        => 'zuul',
    managehome => true,
    require    => Group['zuul'],
  }

  group { 'zuul':
    ensure => present,
  }

  vcsrepo { '/opt/zuul':
    ensure   => latest,
    provider => git,
    revision => $revision,
    source   => $git_source_repo,
  }

  exec { 'install_zuul' :
    command     => "${pip_command} install -U -r/opt/zuul/requirements.txt && ${pip_command} install --no-deps -U /opt/zuul",
    path        => '/usr/local/bin:/usr/bin:/bin/',
    refreshonly => true,
    subscribe   => Vcsrepo['/opt/zuul'],
    require     => [
      Class['pip'],
      Package['build-essential'],
      Package['libffi-dev'],
      Package['libssl-dev'],
      Package['yappi'],
    ],
  }

  if ! $zuulv3 {
    Exec['install_zuul'] -> Package['python-daemon']
    Exec['install_zuul'] -> Package['python-daemon']
    Exec['install_zuul'] -> Package['python-lxml']
    Exec['install_zuul'] -> Package['python-paramiko']
    Exec['install_zuul'] -> Package['python-yaml']
    Exec['install_zuul'] -> Package['yui-compressor']
  }

  file { '/etc/zuul':
    ensure  => directory,
    group   => 'zuul',
    mode    => '0755',
    owner   => 'zuul',
    require => User['zuul'],
  }

  file { '/etc/zuul/ssl':
    ensure  => directory,
    group   => 'zuul',
    mode    => '0755',
    owner   => 'zuul',
    require => File['/etc/zuul'],
  }

  if ($gearman_ssl_ca != undef) {
    file { '/etc/zuul/ssl/ca.pem':
      ensure  => file,
      content => $gearman_ssl_ca,
      group   => 'zuul',
      mode    => '0644',
      owner   => 'zuul',
      require => File['/etc/zuul/ssl'],
    }
  }

  if ($gearman_client_ssl_cert != undef) {
    file { '/etc/zuul/ssl/client.pem':
      ensure  => file,
      content => $gearman_client_ssl_cert,
      group   => 'zuul',
      mode    => '0644',
      owner   => 'zuul',
      require => File['/etc/zuul/ssl'],
    }
  }

  if ($gearman_client_ssl_key != undef) {
    file { '/etc/zuul/ssl/client.key':
      ensure  => file,
      content => $gearman_client_ssl_key,
      group   => 'zuul',
      mode    => '0640',
      owner   => 'zuul',
      require => File['/etc/zuul/ssl'],
    }
  }

  if ($gearman_server_ssl_cert != undef) {
    file { '/etc/zuul/ssl/server.pem':
      ensure  => file,
      content => $gearman_server_ssl_cert,
      group   => 'zuul',
      mode    => '0644',
      owner   => 'zuul',
      require => File['/etc/zuul/ssl'],
    }
  }

  if ($gearman_server_ssl_key != undef) {
    file { '/etc/zuul/ssl/server.key':
      ensure  => file,
      content => $gearman_server_ssl_key,
      group   => 'zuul',
      mode    => '0640',
      owner   => 'zuul',
      require => File['/etc/zuul/ssl'],
    }
  }

  if $zuulv3 {
    $zuul_conf_content = template('zuul/zuulv3.conf.erb')
    $zuul_merger_source = 'puppet:///modules/zuul/zuul-mergerv3.init'
    $zuul_scheduler_source = 'puppet:///modules/zuul/zuul-schedulerv3.init'
  } else {
    $zuul_conf_content = template('zuul/zuul.conf.erb')
    $zuul_merger_source = 'puppet:///modules/zuul/zuul-merger.init'
    $zuul_scheduler_source = 'puppet:///modules/zuul/zuul-scheduler.init'
  }

# TODO: We should put in  notify either Service['zuul'] or Exec['zuul-reload']
#       at some point, but that still has some problems.
  file { '/etc/zuul/zuul.conf':
    ensure  => present,
    owner   => 'zuul',
    mode    => '0400',
    content => $zuul_conf_content,
    require => [
      File['/etc/zuul'],
      User['zuul'],
    ],
  }

  file { '/etc/default/zuul':
    ensure  => present,
    mode    => '0444',
    content => template('zuul/zuul.default.erb'),
  }

  file { '/var/log/zuul':
    ensure  => directory,
    owner   => 'zuul',
    require => User['zuul'],
  }

  file { '/var/run/zuul':
    ensure  => directory,
    owner   => 'zuul',
    group   => 'zuul',
    require => User['zuul'],
  }

  file { '/var/run/zuul-merger':
    ensure  => directory,
    owner   => 'zuul',
    group   => 'zuul',
    require => User['zuul'],
  }

  file { '/var/lib/zuul':
    ensure => directory,
    owner  => 'zuul',
    group  => 'zuul',
  }

  file { '/var/lib/zuul/builds':
    ensure  => directory,
    owner   => 'zuul',
    group   => 'zuul',
    require => File['/var/lib/zuul'],
  }

  file { '/var/lib/zuul/git':
    ensure  => directory,
    owner   => 'zuul',
    require => File['/var/lib/zuul'],
  }

  file { '/var/lib/zuul/ssh':
    ensure  => directory,
    owner   => 'zuul',
    group   => 'zuul',
    mode    => '0500',
    require => File['/var/lib/zuul'],
  }

  file { '/var/lib/zuul/ssh/id_rsa':
    owner   => 'zuul',
    group   => 'zuul',
    mode    => '0400',
    require => File['/var/lib/zuul/ssh'],
    content => $zuul_ssh_private_key,
  }

  if $zuulv3 {
    $v2_web_dirs = [
      '/opt/twitter-bootstrap',
      '/opt/jquery-visibility',
      '/var/lib/zuul/www',
      '/opt/graphitejs',
    ]

    file { $v2_web_dirs:
      ensure => absent,
    }

  } else {

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
  }

  if $zuulv3 {
    file { '/etc/default/zuul-executor':
      ensure  => present,
      mode    => '0444',
      content => "PIDFILE=/var/run/zuul/executor.pid\n",
    }

    file { '/etc/default/zuul-scheduler':
      ensure  => present,
      mode    => '0444',
      content => "PIDFILE=/var/run/zuul/scheduler.pid\n",
    }

    file { '/etc/default/zuul-merger':
      ensure  => present,
      mode    => '0444',
      content => "PIDFILE=/var/run/zuul/merger.pid\n",
    }

    file { '/etc/default/zuul-web':
      ensure  => present,
      mode    => '0444',
      content => "PIDFILE=/var/run/zuul/web.pid\n",
    }
  }

  file { '/etc/init.d/zuul':
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0555',
    source => 'puppet:///modules/zuul/zuul.init',
    notify => Class['zuul::systemd_reload'],
  }

  file { '/etc/init.d/zuul-scheduler':
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0555',
    source => $zuul_scheduler_source,
    notify => Class['zuul::systemd_reload'],
  }

  file { '/etc/init.d/zuul-merger':
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0555',
    source => $zuul_merger_source,
    notify => Class['zuul::systemd_reload'],
  }

  file { '/etc/init.d/zuul-launcher':
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0555',
    source => 'puppet:///modules/zuul/zuul-launcher.init',
    notify => Class['zuul::systemd_reload'],
  }

  file { '/etc/init.d/zuul-executor':
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0555',
    source => 'puppet:///modules/zuul/zuul-executor.init',
    notify => Class['zuul::systemd_reload'],
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

  if $site_variables_yaml_file != undef {
    file { '/etc/zuul/site-variables.yaml':
      ensure  => file,
      group   => 'zuul',
      mode    => '0644',
      owner   => 'zuul',
      replace => true,
      require => File['/etc/zuul'],
      source  => $site_variables_yaml_file,
    }
  }

  if ! $zuulv3 {
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
