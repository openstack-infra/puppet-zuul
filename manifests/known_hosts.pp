# Copyright 2015 Hewlett-Packard Development Company, L.P.
# Copyright 2015 OpenStack Foundation
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

# == Class: zuul::known_hosts
#
class zuul::known_hosts (
  $known_hosts_content
) {
  file { '/home/zuul/.ssh':
    ensure  => directory,
    owner   => 'zuul',
    group   => 'zuul',
    mode    => '0700',
    require => Class['::zuul'],
  }
  file { '/home/zuul/.ssh/known_hosts':
    ensure  => present,
    owner   => 'zuul',
    group   => 'zuul',
    mode    => '0600',
    content => $known_hosts_content,
    replace => true,
    require => File['/home/zuul/.ssh'],
  }
}
