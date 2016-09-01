# zuul

#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with zuul](#setup)
    * [What zuul affects](#what-zuul-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with zuul](#beginning-with-zuul)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Overview

The Zuul module installs, and configures Zuul - A Project Gating System

## Module Description

This module installs Zuul software and configures services on Linux.

## Setup

### What zuul affects

* Creates group and user for zuul services
* Configures SSH client if defined by parameters
* Configures zuul services (via zuul.conf)
* Configures nginx to server Zuul status page
* Optionally configures nginx to serve git repositories prepared by merger

### Setup Requirements

This module intended to be used as part of Mirantis DevOps puppet manifests.
It requres customized nginx module and also custom SSH module.

### Beginning with zuul

The Zuul module requires three parameters to configure access to gerrit: host,
username, and host to be added to known_hosts. If you don't define parameter
ssh_private_key, then default SSH private key will be used, i.e. SSH client
will not be configured.

Also note, even if you don't plan to use git repositories prepared by merger,
zuul requires zuul-merger service, so it is always configured. Serving
git repos via HTTP is enabled by parameter export_merger_repos.

## Usage

All interaction with the ntp module can be done through the main ntp class.

## Reference

### Classes

#### Public Classes

* zuul: Main class, includes all other classes.

###Parameters

The following parameters are available in the `::zuul` class:

####`gerrit_user`

User name to use when logging into Gerrit server via ssh (required).

####`gerrit_server`

FQDN of Gerrit server (required).

####`known_hosts`

FQDN of servers to be added to known_hosts (required).

####`dir`

Directory containing Zuul status files served via HTTP.

####`dir_group`

Directory group.

####`dir_owner`

Directory owner.

####`export_merger_repos`

Wheither to configure Nginx to serve Merger Git repositories.

####`gearman_logconfig`

Gearman logging configuration file.

####`gearman_server`

Hostname or IP address of the Gearman server (127.0.0.1 by default).

####`gerrit_port`

Optional: Gerrit server port (29418 by default).

####`gerrit_baseurl`

Optional: path to Gerrit web interface. Defaults to https://<value of server>/.

####`git_email`

Optional: Value to pass to git config user.email.

####`git_name`

Optional: Value to pass to git config user.name.

####`internal_gearman`

Whether to start the internal Gearman server (true by default).

####`job_name_in_report`

Boolean value that indicates whether the job name should be included in the
report (normally only the URL is included). Used by zuul-server only.

####`layout`

Path to layout config file. Used by zuul-server only.

####`logdir`

Path to logfiles.

####`merger_logconfig`

Merger logging configuration file.

####`nginx_access_log`

Access log file path.

####`nginx_error_log`

Error log file path.

####`nginx_log_format`

Log file format.

####`no_http`

Don't use HTTP(S) for accessing Gerrit.

####`packages`

Packages required to install instance.

####`service_fqdn`

HTTP service FQDN for zuul status.

####`smtp_default_from`

Who the email should appear to be sent from when emailing the report.

####`smtp_default_to`

Who the report should be emailed to by default.

####`smtp_host`

SMTP server hostname or address to use.

####`smtp_port`

Optional: SMTP server port.

####`ssh_private_key`

Path to SSH key to use when logging into above server. If unset, will be
used default (configured via ssh_config) SSH parameters.

####`statedir`

Path to Zuul work (home) directory.

####`status_url`

URL that will be posted in Zuul comments made to Gerrit changes when
starting jobs for a change. Used by zuul-server only.

####`swift_authurl`

The (keystone) Auth URL for swift.

####`swift_auth_version`

OpenStack auth version, default is 1.0.

####`swift_default_container`

Default Swift container.

####`swift_default_logserver_prefix`

Prefix used for logging.

####`swift_key`

Key/password to authenticate with.

####`swift_region_name`

Region name.

####`swift_tenant_name`

The tenant/account name, required when connecting to an auth 2.0 system.

####`swift_user`

User name to authenticate as.

####`url_pattern`

URL to externally stored logs. Used by zuul-server only.

####`zuul_logconfig`

Zuul logging configuration file.

####`zuul_url`

URL of this merger's git repos, accessible to test workers.

## Limitations

This module has been tested only on Ubuntu Trusty, but should be usable on
any Linux distribution.

## Development

If you want to fix bugs or improve module, you can prepare changes via Gerrit:

  ssh://review.fuel-infra.org:29418/fuel-infra/puppet-zuul

Bugs should be reported via Launchpad (assign to fuel-ci):

  https://bugs.launchpad.net/fuel/

## Release Notes/Contributors/Etc

This module is extraced from project fuel-infra/puppet-manifests to be managed by
Mirantis CI team.
