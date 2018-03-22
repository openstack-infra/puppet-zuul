# Copyright 2012-2013 Hewlett-Packard Development Company, L.P.
# Copyright 2014 OpenStack Foundation
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

# == Class: zuul::scheduler
#
class zuul::scheduler (
  $ensure = undef,
  $layout_dir = '',
  $manage_log_conf = true,
  $python_version = 2,
  $use_mysql = false,
) {

  include ::pip

  if ($use_mysql) {
      if ($python_version == 3) {
        include ::pip::python3
        $pip_provider = pip3
        $pip_command = 'pip3'
      } else {
        $pip_provider = openstack_pip
        $pip_command = 'pip'
      }

      package { 'PyMySQL':
        ensure   => present,
        provider => $pip_provider,
        require  => Class['pip'],
      }
      package { 'mysql-client':
        ensure => present
      }
  }

  if ($::operatingsystem == 'Ubuntu') and ($::operatingsystemrelease >= '16.04') {
    # This is a hack to make sure that systemd is aware of the new service
    # before we attempt to start it.
    exec { 'zuul-scheduler-systemd-daemon-reload':
      command     => '/bin/systemctl daemon-reload',
      before      => Service['zuul-scheduler'],
      subscribe   => File['/etc/init.d/zuul-scheduler'],
      refreshonly => true,
    }
  }
  service { 'zuul-scheduler':
    ensure     => $ensure,
    enable     => true,
    hasrestart => true,
    require    => [File['/etc/init.d/zuul-scheduler'],
                  Class['zuul::systemd_reload']]
  }

  exec { 'zuul-reload':
    command     => '/etc/init.d/zuul-scheduler reload',
    require     => File['/etc/init.d/zuul-scheduler'],
    refreshonly => true,
  }

  file { '/etc/zuul/layout':
    ensure  => directory,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    recurse => true,
    purge   => true,
    force   => true,
    source  => $layout_dir,
    require => File['/etc/zuul'],
    notify  => Exec['zuul-reload'],
  }

  if $manage_log_conf {
    file { '/etc/zuul/logging.conf':
      ensure => present,
      source => 'puppet:///modules/zuul/logging.conf',
      notify => Exec['zuul-reload'],
    }

    file { '/etc/zuul/gearman-logging.conf':
      ensure => present,
      source => 'puppet:///modules/zuul/gearman-logging.conf',
      notify => Exec['zuul-reload'],
    }
  }

  include ::logrotate
  ::logrotate::file { 'zuul.log':
    log     => '/var/log/zuul/zuul.log',
    options => [
      'compress',
      'missingok',
      'rotate 30',
      'daily',
      'notifempty',
    ],
    require => Service['zuul-scheduler'],
  }
  ::logrotate::file { 'zuul-debug.log':
    log     => '/var/log/zuul/debug.log',
    options => [
      'compress',
      'missingok',
      'rotate 30',
      'daily',
      'notifempty',
    ],
    require => Service['zuul-scheduler'],
  }
  logrotate::file { 'gearman-server.log':
    log     => '/var/log/zuul/gearman-server.log',
    options => [
      'compress',
      'missingok',
      'rotate 7',
      'daily',
      'notifempty',
    ],
    require => Service['zuul-scheduler'],
  }
}
