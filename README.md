# puppet-galera

[![Build Status](https://travis-ci.org/fraenki/puppet-galera.png?branch=master)](https://travis-ci.org/fraenki/puppet-galera)
[![Puppet Forge](https://img.shields.io/puppetforge/v/fraenki/galera.svg)](https://forge.puppetlabs.com/fraenki/galera)
[![Puppet Forge - downloads](https://img.shields.io/puppetforge/dt/fraenki/galera.svg)](https://forge.puppetlabs.com/fraenki/galera)

NOTE: The "master" branch on GitHub contains the development version, which may break anything at any time. Consider using one of the stable branches instead.

#### Table of Contents

1. [Overview](#overview)
2. [Requirements](#requirements)
3. [Usage](#usage)
    - [Basic usage](#basic-usage)
    - [WSREP provider options](#wsrep-provider-options)
    - [More complex example](#more-complex-example)
    - [Custom repository configuration](#custom-repository-configuration)
    - [FreeBSD support](#freebsd-support)
    - [EPP supported for many options](#epp-supported-for-many-options)
4. [OS and Cluster Compatibility](#os-and-cluster-compatibility)
5. [Reference](#reference)
6. [Limitations](#limitations)
7. [Development](#development)
    - [Contributing](#contributing)

## Overview

This module will massage puppetlabs-mysql into creating a Galera cluster on MySQL, MariaDB or XtraDB. It also supports setting up an Arbitrator node.

It will try to recover from failures by bootstrapping on a node designated as the master if no other nodes appear to be running mysql, but if the cluster goes down and the master is permanently taken out, another node will need to be specified as the 'master' that can bootstrap the cluster.

## Requirements

* Puppet 5 or higher
* puppetlabs-mysql

## Usage

### Basic usage

Basic usage requires only the FQDN of the master node, a list of IP addresses of other nodes and two passwords:

```puppet
class { 'galera':
  cluster_name    => 'mycluster',
  galera_servers  => ['10.0.99.101', '10.0.99.102'],
  galera_master   => 'node1.example.com',
  root_password   => 'pa$$w0rd',
  status_password => 'pa$$w0rd',
}
```

This will install the default galera vendor and version. However, in a production environment you should definitely set vendor and version to the desired value, because the default values might change:

```puppet
class { 'galera':
  vendor_type    => 'percona',
  vendor_version => '5.7',
  ...
```

On Debian/Ubuntu systems the user `debian-sys-maint@localhost` is required for updates and will be created automatically, but you should set a proper password:

```puppet
class { 'galera':
  deb_sysmaint_password => 'secretpassword',
  ...
```

### WSREP provider options

Note that the module will automatically add the required Galera/WSREP provider options to the server configuration.
Currently the following parameters are automatically added: `wsrep_cluster_address`, `wsrep_cluster_name`, `wsrep_node_address`, `wsrep_node_incoming_address`, `wsrep_on`, `wsrep_provider`, `wsrep_slave_threads`, `wsrep_sst_method`, `wsrep_sst_auth`, `wsrep_sst_receive_address`.

Some of these values are used directly from their respective class parameter. For example, to change the SST method:

```puppet
class { 'galera':
  wsrep_sst_method => 'xtrabackup',
  ...
```

Other values like `wsrep_cluster_address` and `wsrep_sst_auth` are generated from several class parameters. Please have a look at the parameter reference and the module's `data` directory for further details.

Of course, all Galera/WSREP provider options can be overridden by using the `$override_options` parameter (see below for an example).

### More complex example

Furthermore, a number of simple options are available to customize the cluster configuration according to your needs:

```puppet
class { 'galera':
  cluster_name    => 'mycluster',
  galera_servers  => ['10.0.99.101', '10.0.99.102'],
  galera_master   => 'node1.example.com',
  root_password   => 'pa$$w0rd',
  status_password => 'pa$$w0rd',

  # Default is 'percona'
  vendor_type     => 'codership',
  vendor_version  => '5.7',

  # This will be used to populate my.cnf values that
  # control where wsrep binds, advertises, and listens
  local_ip => $facts['networking']['ip'],

  # This will be set when the cluster is bootstrapped
  root_password => 'myrootpassword',

  # Disable this if you don't want firewall rules to be set
  configure_firewall => true,

  # Configure the SST method
  wsrep_sst_method => 'xtrabackup',

  # These options are only used for the firewall -
  # to change the my.cnf settings, use the override options
  # described below
  mysql_port => 3306,
  wsrep_state_transfer_port => 4444,
  wsrep_inc_state_transfer_port => 4568,

  # This is used for the firewall + for status checks
  # when deciding whether to bootstrap
  wsrep_group_comm_port => 4567,
}
```

A catch-all parameter `$override_options` can be used to populate my.cnf and overwrite default values in the same way as the puppetlabs-mysql module:

```puppet
class { 'galera':
  override_options => {
    'mysqld' => {
      'bind_address' => '0.0.0.0',
    }
  }
  ...
}
```

### Custom repository configuration

This module automatically determines which APT/YUM repositories need to be configured. This depends on your choices for `$vendor_type`, `$vendor_version` and `$wsrep_sst_method`. Each of these choices may enabled additional repositories.

For example, if setting `$vendor_type=codership` and `$wsrep_sst_method=xtrabackup`, the module will enable the Codership repository to install the Galera server and the Percona repository to install the XtraBackup tool. This works because every vendor/version and SST method may specify the internal `$want_repos` parameter, which is essentially a list of repositories.

Disable repo management if you are managing your own repos and mirrors:

```puppet
class { 'galera':
  configure_repo => false,
  ...
}
```

Or if you just want to switch to using a local mirror, simply change the repo URL for the chosen `$vendor_type`. For Codership you would add something like this to Hiera:

```puppet
# RHEL-based systems
galera::repo::codership::yum:
  baseurl: "http://repo.example.com/RPMS/%{facts.os.release.major}/RPMS/%{facts.os.architecture}/"
  baseurl: "http://repo.example.com/RPMS/<%= $vendor_version_real %>/%{facts.os.release.major}/%{facts.os.architecture}/"
```

```puppet
# Debian-based systems
galera::repo::codership::apt:
  apt_location: "http://repo.example.com/apt/%{facts.os.distro.codename}/"
  ...
```

### FreeBSD support

This module (and all its dependencies) provide support for the FreeBSD operating system. However, from all vendors Codership seems to provide the best support for Galera clusters on FreeBSD. The following configuration is known to work:

```puppet
class { 'galera':
  configure_firewall => false,
  configure_repo     => false,
  galera_servers     => ['10.0.99.101', '10.0.99.102'],
  galera_master      => 'node1.example.com',
  root_password      => 'pa$$w0rd',
  status_password    => 'pa$$w0rd',
  vendor_type        => 'codership',
  vendor_version     => '5.7',
}
```

### EPP supported for many options

This module supports inline EPP for many of its options and parameters. This way class parameters and internal variables can be used when specifying options. Currently this is enabled for `$override_options`, `$wsrep_sst_auth` and all repository options.

    # server/wsrep options
```puppet
galera::override_options:
  mysqld:
    wsrep_sst_method: "<%= $wsrep_sst_method %>"
    wsrep_provider: "<%= $params['libgalera_location'] %>"

galera::wsrep_sst_auth: "root:<%= $root_password %>"
```

    # repo configuration
```puppet
galera::repo::codership::yum:
  baseurl: "http://releases.galeracluster.com/mysql-wsrep-<%= $vendor_version_real %>/%{os_name_lc}/%{os.release.major}/%{os.architecture}/"
  ...
```

## OS and Cluster Compatibility

Note that not all versions of Percona XtraDB, Codership Galera and MariaDB are supported on all operating systems. Please consult the official documentation to find out if your operating system is supported.

Below you will find an **incomplete** and possibly **outdated** list of known (in)compatiblities. Take it with a grain of salt.

|  | RedHat | Debian | Ubuntu | FreeBSD |
| :---     |  :---: |  :---: |  :---: |  :---: |
| **Percona XtraDB Cluster** | 7 / 8 | 9 / 10 | 18.04 | 12.x |
| 5.6 / 5.7 | :green_circle: :no_entry_sign: **/** :green_circle: :green_circle: | :green_circle: :no_entry_sign: **/** :green_circle: :green_circle: | :green_circle: :green_circle: | :no_entry_sign: :no_entry_sign: |
| **Codership Galera** |  |  |  |  |
| 5.6 / 5.7 | :green_circle: :green_circle: **/** :no_entry_sign: :no_entry_sign: | :green_circle: :green_circle: **/** :no_entry_sign: :no_entry_sign: | :green_circle: :green_circle: | :green_circle: :green_circle: |
| **MariaDB Galera Cluster** |  |  |  |  |
| 10.3 / 10.4 | :green_circle: :green_circle: **/** :green_circle: :green_circle: | :green_circle: :green_circle: **/** :green_circle: :green_circle: | :green_circle: :green_circle: | :green_circle: :green_circle: |

The table only includes the **two most recent** versions.
Older and possibly outdated releases are not listed, although they may still be supported by their vendors.

## Reference

Classes and parameters are documented in [REFERENCE.md](REFERENCE.md).

## Limitations

This module was created to work in tandem with the puppetlabs-mysql module, rather than replacing it. As the stages in the mysql module are quite strictly laid out in the `mysql::server` class, this module places its own resources in the gaps between them.

Of note is an `exec` that will start the mysql service with parameters which will bootstrap/start a new cluster, but only if it cannot open the comms port to any other node in the provided list. This is done with a simple `nc` command and should not be considered terribly reliable.

Furthermore the bootstrap functionality may be considered harmful. A better approach is currently being discussed and will be included in a future release ([GH-116](https://github.com/fraenki/puppet-galera/issues/116)).

## Development

### Contributing

Please use the GitHub issues functionality to report any bugs or requests for new features. Feel free to fork and submit pull requests for potential contributions.

All contributions must pass all existing tests, new features should provide additional unit/acceptance tests.
