# puppet-galera module

[![Build Status](https://travis-ci.org/fraenki/puppet-galera.png?branch=master)](https://travis-ci.org/fraenki/puppet-galera)

NEWS: This is the continuation of Michael Chapman's excellent Galera module.

This module will massage puppetlabs-mysql into creating a mysql galera cluster. It will try to recover from failures by bootstrapping on a node designated as the master if no other nodes appear to be running mysql, but if the cluster goes down and the master is permanently taken out, another node will need to be specified as the 'master' that can bootstrap the cluster.

## Requirements

This module depends on, at minimum, the following modules at the listed versions:

    puppetlabs-mysql    3.8.0
    puppetlabs-stdlib   4.1.0

    # If you're on debian and need the repo to be set
    puppetlabs-apt      2.0.0

    # If you want the firewall to be configured for you
    puppetlabs-firewall 1.0.0

    # If using clustercheck
    puppetlabs-xinetd   1.3.0

## Structure

This module was created to work in tandem with the mysql module, rather than replacing it. As the stages in the mysql module are quite strictly laid out in the mysql::server class, this module places its own resources in the gaps between them. Of note is an exec that will start the mysql service with the parameter --wsrep_address=gcomm:// which will start a new cluster, but only if it cannot open the comms port to any other node in the provided list. This is done with a simple nc command and should not be considered terribly reliable.

## Usage

Basic usage requires only the fqdn of the master node, and a list of IP addresses of other nodes:

    class { 'galera':
        galera_servers => ['192.168.99.101', '192.168.99.102'],
        galera_master  => 'control1.domain.name'
    }

A number of simple options are available:

    class { 'galera':
        galera_servers => ['192.168.99.101', '192.168.99.102'],
        galera_master  => 'control1.domain.name',

        vendor_type => 'mariadb', # default is 'percona'

        # These options are only used for the firewall - 
        # to change the my.cnf settings, use the override options
        # described below

        $mysql_port = 3306, 
        $wsrep_state_transfer_port = 4444,
        $wsrep_inc_state_transfer_port = 4568,

        # this is used for the firewall + for status checks
        # when deciding whether to bootstrap
        $wsrep_group_comm_port = 4567,

        local_ip => $::ipaddress_eth0, # This will be used to populate my.cnf values that control where wsrep binds, advertises, and listens
        root_password => 'myrootpassword', # This will be set when the cluster is bootstrapped
        configure_repo => true, # Disable this if you are managing your own repos and mirrors
        configure_firewall => true, # Disable this if you don't want firewall rules to be set
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

## Testing

A vagrant file is provided. Control1 is set as the master and control2 as the slave. It will read environment variables for http_proxy and http_mirror, but these only work on Debian. The module has been tested on Ubuntu 12.04 and Centos 6.4, both 64 bit.

    vagrant up control1
    vagrant up control2

Vagrant support is currently not under active maintenance.

## Contributions

Please use the github issues functionality to report any bugs or requests for new features. Feel free to fork and submit pull requests for potential contributions.

# Authors

Written by Michael Chapman, currently maintained by Frank Wall.
