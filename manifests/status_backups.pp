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

# == Define: zuul::status_backups
#
define zuul::status_backups (
  $tenant_name,
  $ssl,
) {
  if $tenant_name and $tenant_name != '' {
    if $ssl {
      $status = "https://${name}/api/status"
    } else {
      $status = "http://${name}/api/status"
    }
    # Minutes, hours, days, etc are not specified here because we are
    # interested in running this *every minute*.
    # This is a mean of backing up status.json periodically in order to provide
    # a mean of restoring lost scheduler queues if need be.
    # We are downloading this file at a location served by the vhost so that we
    # can query it easily should the need arise.
    # If the status.json is unavailable for download, no new files are created.
    cron { "zuul_scheduler_status_backup-${name}":
      user    => 'root',
      command => "timeout -k 5 10 curl ${status} -o /var/lib/zuul/backup/${name}_status_$(date +\\%s).json 2>/dev/null",
      require => [Package['curl'],
                  User['zuul'],
                  File['/var/lib/zuul/backup']],
    }
    # Rotate backups and keep no more than 120 files -- or 2 hours worth of
    # backup if Zuul has 100% uptime.
    # We're not basing the rotation on time because the scheduler/web service
    # could be down for an extended period of time.
    # This is ran hourly so technically up to ~3 hours worth of backups will
    # be kept.
    cron { "zuul_scheduler_status_prune-${name}":
      user    => 'root',
      minute  => '0',
      command => "flock -n /var/run/${name}_status_prune.lock ls -dt -1 /var/lib/zuul/backup/${name}_* |sed -e '1,120d' |xargs rm -f",
      require => Cron["zuul_scheduler_status_backup-${name}"],
    }
  }
}
