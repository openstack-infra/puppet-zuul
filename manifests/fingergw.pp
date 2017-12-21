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

# == Class: zuul::fingergw
#
class zuul::fingergw (
  $ensure = undef,
  $manage_log_conf = true,
) {

  service { 'zuul-fingergw':
    ensure     => $ensure,
    name       => 'zuul-fingergw',
    enable     => true,
    hasrestart => true,
    require    => [File['/etc/init.d/zuul-fingergw'],
                  Class['zuul::systemd_reload']]
  }

  file { '/etc/init.d/zuul-fingergw':
    ensure => present,
    owner  => 'root',
    group  => 'root',
    mode   => '0555',
    source => 'puppet:///modules/zuul/zuul-fingergw.init',
    notify => Class['zuul::systemd_reload'],
  }

  if $manage_log_conf {
    file { '/etc/zuul/fingergw-logging.conf':
      ensure => present,
      source => 'puppet:///modules/zuul/fingergw-logging.conf',
    }
  }

  include ::logrotate
  ::logrotate::file { 'fingergw.log':
    log     => '/var/log/zuul/fingergw.log',
    options => [
      'compress',
      'missingok',
      'rotate 30',
      'daily',
      'notifempty',
    ],
    require => Service['zuul-fingergw'],
  }
  ::logrotate::file { 'fingergw-debug.log':
    log     => '/var/log/zuul/fingergw-debug.log',
    options => [
      'compress',
      'missingok',
      'rotate 30',
      'daily',
      'notifempty',
    ],
    require => Service['zuul-fingergw'],
  }
}
