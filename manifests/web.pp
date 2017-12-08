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
