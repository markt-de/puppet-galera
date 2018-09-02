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
    - [Public classes](#public-classes)
    - [Private classes](#private-classes)
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

Disable repo management if you are managing your own repos and mirrors:

    class { 'galera':
        configure_repo => disable,
        ...

Or if you just want to switch to using a local mirror:

    # RHEL-based systems
    class { 'galera::repo':
        yum_baseurl => "http://repo.example.com/release/${facts['os']['release']['major']}/RPMS/${facts['os']['architecture']}/",
        ...

    # Debian-based systems
    class { 'galera::repo':
        apt_location => "http://repo.example.com/apt/${facts['os']['distro']['codename']}/",
        ...

## Reference

### Public Classes

#### Class: `galera`

* `additional_packages`:
* `bind_address`:
* `bootstrap_command`:
* `client_package_name`:
* `configure_firewall`:
* `configure_repo`:
* `create_root_my_cnf`:
* `create_root_user`:
* `create_status_user`:
* `deb_sysmaint_password`:
* `default_options`:
* `galera_master`:
* `galera_package_ensure`:
* `galera_package_name`:
* `galera_servers`:
* `local_ip`:
* `manage_additional_packages`:
* `manage_package_nmap`:
* `mysql_package_name`:
* `mysql_port`:
* `mysql_restart`:
* `mysql_service_name`:
* `override_options`:
* `package_ensure`:
* `purge_conf_dir`:
* `root_password`:
* `rundir`:
* `service_enabled`:
* `status_allow`:
* `status_available_when_donor`:
* `status_available_when_readonly`:
* `status_check`:
* `status_host`:
* `status_log_on_failure`:
* `status_log_on_success`:
* `status_log_on_success_operator`:
* `status_password`:
* `status_port`:
* `status_user`:
* `validate_connection`:
* `vendor_type`:
* `vendor_version`:
* `vendor_version_internal`: Internal parameter, *do NOT change!*
* `wsrep_group_comm_port`:
* `wsrep_inc_state_transfer_port`:
* `wsrep_sst_auth`:
* `wsrep_sst_method`:
* `wsrep_state_transfer_port`:

#### Class: `galera::firewall`

* `source`:

#### Class: `galera::repo`

This class will try to automatically lookup the repository data by taking `$galera::vendor_type` and `$galera::vendor_version` into account.

* `apt_repo_include_src`: Specifies whether to include source repo. Valid options: `true` and `false`. Default: `false`.
* `apt_key`: Specifies the GPG key ID of the APT repository. Valid options: a string.
* `apt_key_server`: Specifies the server from which the GPG key should be retrieved. Valid options: a string.
* `apt_location`: Specifies the APT repository URL. Valid options: a string.
* `apt_release`: Specifies a distribution of the APT repository. Valid options: a string. Default: `$facts['os']['distro']['codename']`.
* `apt_repos`: Specifies the component of the APT repository that contains galera packages. Valid options: a string. Default: `main`.
* `epel_needed`: Specifies whether to configure the Epel repository on YUM systems. Valid options: `true` and `false`. Default: `true`.
* `vendor_type`: Internal parameter, *do NOT change!*
* `yum_baseurl`: Specifies the YUM repository URL. Valid options: a string.
* `yum_descr`: Specifies the YUM repository description. Valid options: a string.
* `yum_enabled`: Specifies whether to enable the YUM repository. Valid options: `true` and `false`. Default: `true`.
* `yum_gpgcheck`: Specifies whether to verify packages using the specified GPG key. Valid options: `true` and `false`. Default: `true`.
* `yum_gpgkey`: Specifies the GPG key ID of the YUM repository. Valid options: a string.

### Private Classes

#### Class: `galera::debian`

This private class adds several workarounds to solve issues specific to Debian-based systems.

#### Class: `galera::mariadb`

This private class fixes issue when using MariaDB.

#### Class: `galera::status`

This private class configures a user and script that will check the status of the galera cluster.

#### Class: `galera::validate`

This private accept connections at the point where the `mysql::server` resource is marked as complete.
This is used because after returning success, the service is still not quite ready.

## Limitations

This module was created to work in tandem with the puppetlabs-mysql module, rather than replacing it. As the stages in the mysql module are quite strictly laid out in the mysql::server class, this module places its own resources in the gaps between them.

Of note is an exec that will start the mysql service with the parameter --wsrep_address=gcomm:// which will start a new cluster, but only if it cannot open the comms port to any other node in the provided list. This is done with a simple nc command and should not be considered terribly reliable.

Furthermore the bootstrap functionality may be considered harmful. A better approach is currently being discussed and will be included in a future release ([GH-116](https://github.com/fraenki/puppet-galera/issues/116)).

## Development

### Contributing

Please use the GitHub issues functionality to report any bugs or requests for new features. Feel free to fork and submit pull requests for potential contributions.
