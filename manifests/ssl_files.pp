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

# == Define: zuul::ssl_files
#
define zuul::ssl_files (
  $ssl_cert_file_contents,
  $ssl_key_file_contents,
  $ssl_chain_file_contents,
) {
  file { "/etc/ssl/certs/${name}.pem":
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => $ssl_cert_file_contents,
    require => File['/etc/ssl/certs'],
    before  => Httpd::Vhost[$name],
  }
  file { "/etc/ssl/private/${name}.key":
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    content => $ssl_key_file_contents,
    require => File['/etc/ssl/private'],
    before  => Httpd::Vhost[$name],
  }
  if $ssl_chain_file_contents != '' {
    file { "/etc/ssl/certs/${name}_intermediate.pem":
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => $ssl_chain_file_contents,
      require => File['/etc/ssl/certs'],
      before  => Httpd::Vhost[$name],
    }
  }
}
