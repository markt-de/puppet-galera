# puppet-galera

[![Build Status](https://travis-ci.org/fraenki/puppet-galera.png?branch=master)](https://travis-ci.org/fraenki/puppet-galera)

NOTE: Do NOT use the "master" branch, it may break at any time. If you really need to, use one of the stable branches instead.

#### Table of Contents

1. [Overview](#overview)
2. [Requirements](#requirements)
3. [Usage](#usage)
    - [Beginning with galera](#beginning-with-galera)
    - [Custom repository configuration](#custom-repository-configuration)
4. [Reference](#reference)
    - [Public classes][]
    - [Private classes][]
    - [Templates][]
5. [Limitations](#limitations)
6. [Development](#development)
    - [Contributing](#contributing)

## Overview

This module will massage puppetlabs-mysql into creating a MySQL or MariaDB galera cluster.

It will try to recover from failures by bootstrapping on a node designated as the master if no other nodes appear to be running mysql, but if the cluster goes down and the master is permanently taken out, another node will need to be specified as the 'master' that can bootstrap the cluster.

## Requirements

* Puppet 4.10 or higher
* puppetlabs-mysql

## Usage

### Beginning with galera

Basic usage requires only the fqdn of the master node, and a list of IP addresses of other nodes:

    class { 'galera':
        galera_servers => ['192.168.99.101', '192.168.99.102'],
        galera_master  => 'control1.domain.name'
    }

A number of simple options are available:

    class { 'galera':
        galera_servers => ['192.168.99.101', '192.168.99.102'],
        galera_master  => 'control1.domain.name',

        # Default is 'percona'
        vendor_type => 'codership',

        # This will be used to populate my.cnf values that
        # control where wsrep binds, advertises, and listens
        local_ip => $::ipaddress_eth0,

        # This will be set when the cluster is bootstrapped
        root_password => 'myrootpassword',

        # Disable this if you are managing your own repos and mirrors
        configure_repo => true,

        # Disable this if you don't want firewall rules to be set
        configure_firewall => true,

        # These options are only used for the firewall - 
        # to change the my.cnf settings, use the override options
        # described below
        $mysql_port = 3306, 
        $wsrep_state_transfer_port = 4444,
        $wsrep_inc_state_transfer_port = 4568,

        # This is used for the firewall + for status checks
        # when deciding whether to bootstrap
        $wsrep_group_comm_port = 4567,
    }

A catch-all parameter can be used to populate my.cnf in the same way as the puppetlabs-mysql module:

    class { 'galera':
        galera_servers => ['192.168.99.101', '192.168.99.102'],
        galera_master  => 'control1.domain.name',

        override_options = {
            'mysqld' => {
                'bind_address' => '0.0.0.0',
            }
        }
    }

### Custom repository configuration




## Limitations

This module was created to work in tandem with the puppetlabs-mysql module, rather than replacing it. As the stages in the mysql module are quite strictly laid out in the mysql::server class, this module places its own resources in the gaps between them.

Of note is an exec that will start the mysql service with the parameter --wsrep_address=gcomm:// which will start a new cluster, but only if it cannot open the comms port to any other node in the provided list. This is done with a simple nc command and should not be considered terribly reliable.

Furthermore the bootstrap functionality may be considered harmful. A better approach is currently being discussed and will be included in a future release ([GH-116](https://github.com/fraenki/puppet-galera/issues/116)).

## Development

### Contributing

Please use the GitHub issues functionality to report any bugs or requests for new features. Feel free to fork and submit pull requests for potential contributions.
