# puppet-galera

[![Build Status](https://travis-ci.org/fraenki/puppet-galera.png?branch=master)](https://travis-ci.org/fraenki/puppet-galera)

NOTE: The "master" branch on GitHub contains the development version, which may break anything at any time. Consider using one of the stable branches instead.

#### Table of Contents

1. [Overview](#overview)
2. [Requirements](#requirements)
3. [Usage](#usage)
    - [Basic usage](#basic-usage)
    - [More complex example](#more-complex-example)
    - [Custom repository configuration](#custom-repository-configuration)
    - [FreeBSD support](#freebsd-support)
4. [Reference](#reference)
5. [Limitations](#limitations)
6. [Development](#development)
    - [Contributing](#contributing)

## Overview

This module will massage puppetlabs-mysql into creating a MySQL or MariaDB galera cluster.

It will try to recover from failures by bootstrapping on a node designated as the master if no other nodes appear to be running mysql, but if the cluster goes down and the master is permanently taken out, another node will need to be specified as the 'master' that can bootstrap the cluster.

## Requirements

* Puppet 5 or higher
* puppetlabs-mysql

## Usage

### Basic usage

Basic usage requires only the FQDN of the master node, a list of IP addresses of other nodes and two passwords:

```puppet
class { 'galera':
  galera_servers  => ['10.0.99.101', '10.0.99.102'],
  galera_master   => 'node1.example.com',
  root_password   => 'pa$$w0rd',
  status_password => 'pa$$w0rd',
}
```

This will install the default galera vendor and version. However, in a production environment you should definitely specify the vendor and version to avoid accidential updates:

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

### More complex example

Furthermore, a number of simple options are available to customize the cluster configuration according to your needs:

```puppet
class { 'galera':
  galera_servers  => ['10.0.99.101', '10.0.99.102'],
  galera_master   => 'node1.example.com',
  root_password   => 'pa$$w0rd',
  status_password => 'pa$$w0rd',

  # Default is 'percona'
  vendor_type     => 'codership',

  # This will be used to populate my.cnf values that
  # control where wsrep binds, advertises, and listens
  local_ip => $facts['networking']['ip'],

  # This will be set when the cluster is bootstrapped
  root_password => 'myrootpassword',

  # Disable this if you don't want firewall rules to be set
  configure_firewall => true,

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

Disable repo management if you are managing your own repos and mirrors:

```puppet
class { 'galera':
  configure_repo => false,
  ...
}
```

Or if you just want to switch to using a local mirror:

    # RHEL-based systems
```puppet
class { 'galera::repo':
  yum_baseurl => "http://repo.example.com/release/${facts['os']['release']['major']}/RPMS/${facts['os']['architecture']}/",
  ...
```
    # Debian-based systems
```puppet
class { 'galera::repo':
  apt_location => "http://repo.example.com/apt/${facts['os']['distro']['codename']}/",
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

## Reference

Classes and parameters are documented in [REFERENCE.md](REFERENCE.md).

## Limitations

This module was created to work in tandem with the puppetlabs-mysql module, rather than replacing it. As the stages in the mysql module are quite strictly laid out in the `mysql::server` class, this module places its own resources in the gaps between them.

Of note is an `exec` that will start the mysql service with parameters which will bootstrap/start a new cluster, but only if it cannot open the comms port to any other node in the provided list. This is done with a simple `nc` command and should not be considered terribly reliable.

Furthermore the bootstrap functionality may be considered harmful. A better approach is currently being discussed and will be included in a future release ([GH-116](https://github.com/fraenki/puppet-galera/issues/116)).

## Development

### Contributing

Please use the GitHub issues functionality to report any bugs or requests for new features. Feel free to fork and submit pull requests for potential contributions.
