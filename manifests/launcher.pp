# Copyright 2012-2013 Hewlett-Packard Development Company, L.P.
# Copyright 2014 OpenStack Foundation
# Copyright 2016 IBM Corp.
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

# == Class: zuul::launcher
#
class zuul::launcher (
  $ensure = undef,
  $manage_log_conf = true,
) {
  service { 'zuul-launcher':
    ensure     => $ensure,
    name       => 'zuul-launcher',
    enable     => true,
    hasrestart => true,
    require    => File['/etc/init.d/zuul-launcher'],
  }

  exec { 'zuul-launcher-reload':
    command     => '/etc/init.d/zuul-launcher reload',
    require     => File['/etc/init.d/zuul-launcher'],
    refreshonly => true,
  }

  if $manage_log_conf {
    file { '/etc/zuul/launcher-logging.conf':
      ensure => present,
      source => 'puppet:///modules/zuul/launcher-logging.conf',
    }
  }

  package { 'lftp':
    ensure => present,
  }

  package { 'pyzmq':
    ensure   => present,
    provider => openstack_pip,
    require  => Class['pip'],
  }

  package { 'jenkins-job-builder':
    ensure   => present,
    provider => openstack_pip,
    require  => Class['pip'],
  }

  package { 'ansible':
    ensure   => '2.1.0.0',
    provider => openstack_pip,
    require  => Class['pip'],
  }

  include ::logrotate
  ::logrotate::file { 'launcher.log':
    log     => '/var/log/zuul/launcher.log',
    options => [
      'compress',
      'missingok',
      'rotate 30',
      'daily',
      'notifempty',
    ],
    require => Service['zuul-launcher'],
  }
  ::logrotate::file { 'launcher-debug.log':
    log     => '/var/log/zuul/launcher-debug.log',
    options => [
      'compress',
      'missingok',
      'rotate 30',
      'daily',
      'notifempty',
    ],
    require => Service['zuul-launcher'],
  }
}
