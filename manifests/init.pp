# == Class: zuul
#
# This class deploys Zuul instance.
#
# === Parameters
#
# [*gerrit_user*]
#   User name to use when logging into Gerrit server via ssh (required).
#
# [*gerrit_server*]
#   FQDN of Gerrit server (required).
#
# [*known_hosts*]
#   FQDN of servers to be added to known_hosts (required).
#
# [*dir*]
#   Directory containing Zuul status files served via HTTP.
#
# [*dir_group*]
#   Directory group.
#
# [*dir_owner*]
#   Directory owner.
#
# [*export_merger_repos*]
#   Wheither to configure Nginx to serve Merger Git repositories.
#
# [*gearman_logconfig*]
#   Gearman logging configuration file.
#
# [*gearman_server*]
#   Hostname or IP address of the Gearman server (127.0.0.1 by default).
#
# [*gerrit_port*]
#   Optional: Gerrit server port (29418 by default).
#
# [*gerrit_baseurl*]
#   Optional: path to Gerrit web interface.
#   Defaults to https://<value of server>/.
#
# [*git_email*]
#   Optional: Value to pass to git config user.email.
#
# [*git_name*]
#   Optional: Value to pass to git config user.name.
#
# [*internal_gearman*]
#   Whether to start the internal Gearman server (true by default).
#
# [*job_name_in_report*]
#   Boolean value that indicates whether the job name should be included in the
#   report (normally only the URL is included). Used by zuul-server only.
#
# [*layout*]
#   Path to layout config file. Used by zuul-server only.
#
# [*logdir*]
#   Path to logfiles.
#
# [*merger_logconfig*]
#   Merger logging configuration file.
#
# [*nginx_access_log*]
#   Access log file path.
#
# [*nginx_error_log*]
#   Error log file path.
#
# [*nginx_log_format*]
#   Log file format.
#
# [*no_http*]
#   Don't use HTTP(S) for accessing Gerrit.
#
# [*packages*]
#   Packages required to install instance.
#
# [*service_fqdn*]
#   HTTP service FQDN.
#
# [*smtp_default_from*]
#   Who the email should appear to be sent from when emailing the report.
#
# [*smtp_default_to*]
#   Who the report should be emailed to by default.
#
# [*smtp_host*]
#   SMTP server hostname or address to use.
#
# [*smtp_port*]
#   Optional: SMTP server port.
#
# [*ssh_private_key*]
#   Path to SSH key to use when logging into above server. If unset, will be
#   used default (configured via ssh_config) SSH parameters.
#
# [*statedir*]
#   Path to Zuul work (home) directory.
#
# [*status_url*]
#   URL that will be posted in Zuul comments made to Gerrit changes when
#   starting jobs for a change. Used by zuul-server only.
#
# [*swift_authurl*]
#   The (keystone) Auth URL for swift.
#
# [*swift_auth_version*]
#   OpenStack auth version, default is 1.0.
#
# [*swift_default_container*]
#   Default Swift container.
#
# [*swift_default_logserver_prefix*]
#   Prefix used for logging.
#
# [*swift_key*]
#   Key/password to authenticate with.
#
# [*swift_region_name*]
#   Region name.
#
# [*swift_tenant_name*]
#   The tenant/account name, required when connecting to an auth 2.0 system.
#
# [*swift_user*]
#   User name to authenticate as.
#
# [*url_pattern*]
#   URL to externally stored logs. Used by zuul-server only.
#
# [*zuul_logconfig*]
#   Zuul logging configuration file.
#
# [*zuul_url*]
#   URL of this merger's git repos, accessible to test workers.
#
# === Examples
#
#  class { 'zuul':
#    gerrit_user   => 'user',
#    gerrit_server => 'review.example.com',
#    known_hosts   => 'review.example.com',
#  }
#
# === Authors
#
# Dmitry Kaigarodtsev <dkaiharodsev@mirantis.com>
# Sergey Kulanov <skulanov@mirantis.com>
# Pawel Brzozowski <pbrzozowski@mirantis.com>
# Igor Shishkin <me@teran.ru>
# Alexander Evseev <aevseev@mirantis.com>
# Artur Kaszuba <akaszuba@mirantis.com>
# Mateusz Matuszkowiak <mmatuszkowiak@mirantis.com>
#
# === Copyright
#
# Copyright 2016 Mirantis, Inc.
#
class zuul (
  $gerrit_user,
  $gerrit_server,
  $known_hosts,
  $dir                            = '/usr/share/zuul/public_html',
  $dir_group                      = 'www-data',
  $dir_owner                      = 'www-data',
  $export_merger_repos            = false,
  $gearman_logconfig              = '/etc/zuul/gearman-logging.conf',
  $gearman_server                 = '127.0.0.1',
  $gerrit_port                    = '29418',
  $gerrit_baseurl                 = undef,
  $git_email                      = undef,
  $git_name                       = undef,
  $internal_gearman               = true,
  $job_name_in_report             = false,
  $layout                         = '/etc/zuul/layout.yaml',
  $logdir                         = '/var/log/zuul',
  $merger_logconfig               = '/etc/zuul/merger-logging.conf',
  $nginx_access_log               = '/var/log/nginx/access.log',
  $nginx_error_log                = '/var/log/nginx/error.log',
  $nginx_log_format               = undef,
  $no_http                        = false,
  $packages                       = [
    'nginx',
    'zuul',
  ],
  $service_fqdn                   = 'zuul.local',
  $smtp_default_from              = "zuul@${::fqdn}",
  $smtp_default_to                = "zuul.reports@${::fqdn}",
  $smtp_host                      = undef,
  $smtp_port                      = 25,
  $ssh_private_key                = undef,
  $statedir                       = '/var/lib/zuul',
  $status_url                     = "http://${::fqdn}/",
  $swift_authurl                  = undef,
  $swift_auth_version             = undef,
  $swift_default_container        = 'default',
  $swift_default_logserver_prefix = 'logserver_prefix',
  $swift_key                      = 'swift_password',
  $swift_region_name              = 'some_region',
  $swift_tenant_name              = 'some_tenant',
  $swift_user                     = 'swift_user',
  $url_pattern                    = undef,
  $zuul_logconfig                 = '/etc/zuul/zuul-logging.conf',
  $zuul_url                       = "http://${::fqdn}/p",
) {

  ensure_resource('user', $dir_owner, {
    ensure => 'present',
  })

  ensure_resource('group', $dir_group, {
    ensure => 'present',
  })

  ensure_packages($packages)

  file { '/etc/zuul/zuul.conf':
    content => template('zuul/zuul.conf.erb'),
    require => Package[ $packages ],
  }

  file { $logdir:
    ensure  => directory,
    owner   => 'zuul',
    group   => 'zuul',
    mode    => '0755',
    require => Package[ $packages ],
  }

  file { $gearman_logconfig:
    content => template('zuul/gearman-logging.conf.erb'),
    require => [
      Package[ $packages ],
      File[ $logdir ],
    ],
  }

  file { $merger_logconfig:
    content => template('zuul/merger-logging.conf.erb'),
    require => [
      Package[ $packages ],
      File[ $logdir ],
    ],
  }

  file { $zuul_logconfig:
    content => template('zuul/zuul-logging.conf.erb'),
    require => [
      Package[ $packages ],
      File[ $logdir ],
    ],
  }

  file { $statedir:
    ensure  => directory,
    owner   => 'zuul',
    group   => 'zuul',
    mode    => '0755',
    require => Package[ $packages ],
  }

  # Prepare SSH connection
  if ( $ssh_private_key ) {

    file { "${statedir}/.ssh":
      ensure  => directory,
      owner   => 'zuul',
      group   => 'zuul',
      mode    => '0700',
      require => File[ $statedir ],
    }

    file { "${statedir}/.ssh/id_rsa.${gerrit_server}":
      owner   => 'zuul',
      group   => 'zuul',
      mode    => '0400',
      content => $ssh_private_key,
      require => File[ "${statedir}/.ssh" ],
    }

    file { "${statedir}/.ssh/config":
      owner   => 'zuul',
      group   => 'zuul',
      content => template('zuul/ssh_config.erb'),
      require => File[ "${statedir}/.ssh", "${statedir}/.ssh/id_rsa.${gerrit_server}" ],
    }

    create_resources('ssh::known_host', $known_hosts, {
      user    => 'zuul',
      require => File[ "${statedir}/.ssh" ],
    })

  }

  file { $dir :
    ensure  => 'directory',
    owner   => $dir_owner,
    group   => $dir_group,
    mode    => '0755',
    require => [
        Class['nginx'],
        User[$dir_owner],
        Group[$dir_group],
      ],
  }

  include ::nginx

  # zuul configuration for nginx adopted from
  # https://github.com/openstack-infra/puppet-zuul/blob/master/templates/zuul.vhost.erb
  ::nginx::resource::vhost { 'zuul' :
    ensure      => 'present',
    www_root    => $dir,
    access_log  => $nginx_access_log,
    error_log   => $nginx_error_log,
    format_log  => $nginx_log_format,
    server_name => [
      $service_fqdn,
      "zuul.${::fqdn}",
    ],
  }

  ::nginx::resource::location { 'status.json' :
    ensure   => 'present',
    location => '/status.json',
    vhost    => 'zuul',
    proxy    => 'http://127.0.0.1:8001/status.json',
  }

  # Correctly use matching for zuul status targeted pass through so that
  # we can get the optimized per change zuul results.
  ::nginx::resource::location { 'status' :
    ensure   => 'present',
    location => '~ ^/status/(.*)',
    vhost    => 'zuul',
    proxy    => 'http://127.0.0.1:8001/status/$1',
  }

  # To serve merger's Git repositories it's needed to use CGI program
  # "git-http-backend" but Nginx can't be used with CGI directly.
  if ( $export_merger_repos ) {

    package{ 'fcgiwrap': ensure => present }

    $git_home = $osfamily ? {
      'Debian' => '/usr/lib/git-core',
      'RedHat' => '/usr/libexec/git-core',
      'Suse'   => '/usr/lib/git',
    }

    ::nginx::resource::location{ 'git-repos':
      ensure                 => present,
      location               => '~ ^/p(/.*)',
      vhost                  => 'zuul',
      fastcgi                => 'unix:/run/fcgiwrap.socket',
      fastcgi_param          => {
        'DOCUMENT_ROOT'       => $git_home,
        'GIT_HTTP_EXPORT_ALL' => '""',
        'GIT_PROJECT_ROOT'    => "${statedir}/git/",
        'PATH_INFO'           => '$1',
        'SCRIPT_FILENAME'     => "${git_home}/git-http-backend",
        'CONTENT_LENGTH'      => '$content_length',
        'CONTENT_TYPE'        => '$content_type',
        'DOCUMENT_URI'        => '$document_uri',
        'GATEWAY_INTERFACE'   => 'CGI/1.1',
        'HTTPS'               => '$https if_not_empty',
        'QUERY_STRING'        => '$query_string',
        'REMOTE_ADDR'         => '$remote_addr',
        'REMOTE_PORT'         => '$remote_port',
        'REQUEST_METHOD'      => '$request_method',
        'REQUEST_URI'         => '$request_uri',
        'SCRIPT_NAME'         => '$fastcgi_script_name',
        'SERVER_ADDR'         => '$server_addr',
        'SERVER_NAME'         => '$server_name',
        'SERVER_PORT'         => '$server_port',
        'SERVER_PROTOCOL'     => '$server_protocol',
        'SERVER_SOFTWARE'     => 'nginx/$nginx_version',
      },
      fastcgi_params_include => false,
    }
  }

}
