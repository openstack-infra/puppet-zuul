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
) {

  service { 'zuul-web':
    ensure     => $ensure,
    name       => 'zuul-web',
    enable     => true,
    hasrestart => true,
    require    => [File['/etc/init.d/zuul-web'],
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

  if !defined(Package['curl']) {
    package { 'curl':
      ensure => present
    }
  }

  file { '/var/lib/zuul/www/backup':
    ensure  => directory,
    require => File['/var/lib/zuul/www'],
  }

  if $enable_status_backups {
    # Minutes, hours, days, etc are not specified here because we are
    # interested in running this *every minute*.
    # This is a mean of backing up status.json periodically in order to provide
    # a mean of restoring lost scheduler queues if need be.
    # We are downloading this file at a location served by the vhost so that we
    # can query it easily should the need arise.
    # If the status.json is unavailable for download, no new files are created.
    if $zuul::proxy_ssl_cert_file_contents != '' {
      $status = "https://${zuul::vhost_name}/status.json"
    } else {
      $status = "http://${zuul::vhost_name}/status.json"
    }
    cron { 'zuul_scheduler_status_backup':
      user    => 'root',
      command => "timeout -k 5 10 curl ${status} -o /var/lib/zuul/www/backup/status_$(date +\\%s).json",
      require => [Package['curl'],
                  User['zuul'],
                  File['/var/lib/zuul/www/backup']],
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
      command => 'flock -n /var/run/status_prune.lock ls -dt -1 /var/lib/zuul/www/backup/* |sed -e "1,120d" |xargs rm -f',
      require => Cron['zuul_scheduler_status_backup'],
    }
  }

  file { '/var/lib/zuul/www/static':
    ensure  => directory,
    require => File['/var/lib/zuul/www'],
  }

  file { '/var/lib/zuul/www/static/js':
    ensure  => directory,
    require => File['/var/lib/zuul/www/static'],
  }

  file { '/var/lib/zuul/www/static/js/jquery.min.js':
    ensure  => link,
    target  => '/usr/share/javascript/jquery/jquery.min.js',
    require => [File['/var/lib/zuul/www/static/js'],
                Package['libjs-jquery']],
  }

  file { '/var/lib/zuul/www/static/bootstrap':
    ensure  => link,
    target  => '/opt/twitter-bootstrap/dist',
    require => [File['/var/lib/zuul/www/static'],
                Package['libjs-jquery'],
                Vcsrepo['/opt/twitter-bootstrap']],
  }

  exec { 'install-jquery-visibility-zuul-web':
    command     => 'yui-compressor -o /var/lib/zuul/www/static/js/jquery-visibility.js /opt/jquery-visibility/jquery-visibility.js',
    path        => 'bin:/usr/bin',
    refreshonly => true,
    subscribe   => Vcsrepo['/opt/jquery-visibility'],
    require     => [File['/var/lib/zuul/www/static/js'],
                    Package['yui-compressor'],
                    Vcsrepo['/opt/jquery-visibility']],
  }

  file { '/var/lib/zuul/www/static/js/jquery.graphite.js':
    ensure  => link,
    target  => '/opt/graphitejs/jquery.graphite.js',
    require => [File['/var/lib/zuul/www/static/js'],
                Vcsrepo['/opt/graphitejs']],
  }

  # Download angular
  # NOTE: This is using a hardcoded URL because soon this will shift to being
  # based on a more javascript-native toolchain.
  exec { 'get-angular-zuul-web':
    command => 'curl https://code.angularjs.org/1.5.8/angular.min.js -z /var/lib/zuul/www/static/js/angular.min.js -o /var/lib/zuul/www/static/js/angular.min.js',
    path    => '/bin:/usr/bin',
    require => [Package[curl],
                File['/var/lib/zuul/www/static/js']],
    onlyif  => "curl -I https://code.angularjs.org/1.5.8/angular.min.js -z /var/lib/zuul/www/static/js/angular.min.js | grep '200 OK'",
    creates => '/var/lib/zuul/www/static/js/angular.min.js',
  }

  # For now, symlink in the static parts of zuul-web which are not
  # tenant-scoped since they share a URL space with the external
  # dependencies.
  file { '/var/lib/zuul/www/static/javascripts':
    ensure  => link,
    target  => '/opt/zuul/zuul/web/static/javascripts',
    require => [File['/var/lib/zuul/www/static'],
                Vcsrepo['/opt/zuul']],
  }
  file { '/var/lib/zuul/www/static/images':
    ensure  => link,
    target  => '/opt/zuul/zuul/web/static/images',
    require => [File['/var/lib/zuul/www/static'],
                Vcsrepo['/opt/zuul']],
  }
  file { '/var/lib/zuul/www/static/styles':
    ensure  => link,
    target  => '/opt/zuul/zuul/web/static/styles',
    require => [File['/var/lib/zuul/www/static'],
                Vcsrepo['/opt/zuul']],
  }
}
