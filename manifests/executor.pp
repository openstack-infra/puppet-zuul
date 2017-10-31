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

# == Class: zuul::executor
#
class zuul::executor (
  $ensure = undef,
  $manage_log_conf = true,
) {
  include ::apt
  apt::ppa { 'ppa:openstack-ci-core/bubblewrap': }
  # Temporary PPA needed for bpo-27945 while waiting for SRU to be published
  apt::ppa { 'ppa:openstack-ci-core/python-bpo-27945-backport': }

  package { 'bubblewrap':
    ensure  => present,
    require => [
      Apt::Ppa['ppa:openstack-ci-core/bubblewrap'],
      Class['apt::update'],
    ],
  }

  include ::pip::python3

  package { 'ara':
    ensure   => latest,
    provider => 'pip3',
    require  => Class['pip'],
  }

  if ($::operatingsystem == 'Ubuntu') and ($::operatingsystemrelease >= '16.04') {
    # This is a hack to make sure that systemd is aware of the new service
    # before we attempt to start it.
    exec { 'zuul-executor-systemd-daemon-reload':
      command     => '/bin/systemctl daemon-reload',
      before      => Service['zuul-executor'],
      subscribe   => File['/etc/init.d/zuul-executor'],
      refreshonly => true,
    }
  }

  service { 'zuul-executor':
    ensure     => $ensure,
    name       => 'zuul-executor',
    enable     => true,
    hasrestart => true,
    require    => [File['/etc/init.d/zuul-executor'],
                  Class['zuul::systemd_reload']]
  }

  if $manage_log_conf {
    file { '/etc/zuul/executor-logging.conf':
      ensure => present,
      source => 'puppet:///modules/zuul/executor-logging.conf',
    }
  }

  include ::logrotate
  ::logrotate::file { 'executor.log':
    log     => '/var/log/zuul/executor.log',
    options => [
      'compress',
      'missingok',
      'rotate 30',
      'daily',
      'notifempty',
    ],
    require => Service['zuul-executor'],
  }
  ::logrotate::file { 'executor-debug.log':
    log     => '/var/log/zuul/executor-debug.log',
    options => [
      'compress',
      'missingok',
      'rotate 30',
      'daily',
      'notifempty',
    ],
    require => Service['zuul-executor'],
  }
}
