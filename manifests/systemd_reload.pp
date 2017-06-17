# zuul::systemd_reload
#
class zuul::systemd_reload(
) {
  if versioncmp($::operatingsystemmajversion, '16.04') >= 0 and ! defined(Exec['systemctl-daemon-reload']) {
    exec {'systemctl-daemon-reload':
      command     => 'systemctl daemon-reload',
      path        => '/bin:/usr/bin',
      refreshonly => true,
    }
  }
}
