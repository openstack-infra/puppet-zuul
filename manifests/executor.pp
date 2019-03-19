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

  # Alternative malloc implementation with better packing performance
  if ! defined(Package['libjemalloc1']) {
    package { 'libjemalloc1':
      ensure => present,
    }
  }

  exec { 'zuul_manage_ansible':
    command     => 'zuul-manage-ansible',
    environment => ['ANSIBLE_EXTRA_PACKAGES=gear'],
    path        => '/usr/local/bin:/usr/bin:/bin/',
    subscribe   => Exec['install_zuul'],
    refreshonly => true,
  }

  include ::pip::python3

  exec { 'install-ara-safely':
    command => 'pip3 install --upgrade --upgrade-strategy=only-if-needed ara',
    path    => '/usr/local/bin:/usr/bin:/bin/',
    # This checks the current installed ara version with pip list and the
    # latest version of ara on pypi with pip search and if they are different
    # then we know we need to upgrade to reconcile the local version with
    # the upstream version.
    #
    # We do this using this check here rather than a pip package resource so
    # that ara's deps don't inadverdently update zuuls deps (specifically
    # ansible).
    #
    onlyif  => '/bin/bash -c "test \\"$(pip3 list --format columns | sed -ne \'s/^ara\s\+\([.0-9]\+\)\s\+$/\1/p\')\\" != \\"$(pip3 search \'ara$\' | sed -ne \'s/^ara (\(.*\)).*$/\1/p\')\\""',
    require => Class['::pip::python3'],
  }

  # openstacksdk is used by the swift role in zuul-jobs
  package { 'openstacksdk':
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
