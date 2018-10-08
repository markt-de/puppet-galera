# puppet-galera

[![Build Status](https://travis-ci.org/fraenki/puppet-galera.png?branch=master)](https://travis-ci.org/fraenki/puppet-galera)

NOTE: The "master" branch contains the development version, which may break anything at any time. Consider using one of the stable branches instead.

#### Table of Contents

1. [Overview](#overview)
2. [Requirements](#requirements)
3. [Usage](#usage)
    - [Beginning with galera](#beginning-with-galera)
    - [Custom repository configuration](#custom-repository-configuration)
4. [Reference](#reference)
    - [Public classes](#public-classes)
        - [galera](#class-galera)
        - [galera::firewall](#class-galerafirewall)
        - [galera::repo](#class-galerarepo)
    - [Private classes](#private-classes)
        - [galera::debian](#class-galeradebian)
        - [galera::mariadb](#class-galeramariadb)
        - [galera::status](#class-galerastatus)
        - [galera::validate](#class-galeravalidate)
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

Basic usage requires only the FQDN of the master node, a list of IP addresses of other nodes and two passwords:

    class { 'galera':
        galera_servers  => ['10.0.99.101', '10.0.99.102'],
        galera_master   => 'node1.example.com',
        root_password   => 'pa$$w0rd',
        status_password => 'pa$$w0rd',
    }

This will install the default galera vendor and version. However, in a production environment you should definitely specify the vendor and version to avoid accidential updates:

    class { 'galera':
        vendor_type     => 'percona',
        vendor_version  => '5.7',
        ...

On Debian/Ubuntu systems the user `debian-sys-maint@localhost` is required for updates and will be created automatically, but you should set a proper password:

    class { 'galera':
        deb_sysmaint_password => 'secretpassword',
        ...

Furthermore, a number of simple options are available:

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
        $mysql_port = 3306, 
        $wsrep_state_transfer_port = 4444,
        $wsrep_inc_state_transfer_port = 4568,

        # This is used for the firewall + for status checks
        # when deciding whether to bootstrap
        $wsrep_group_comm_port = 4567,
    }

A catch-all parameter can be used to populate my.cnf in the same way as the puppetlabs-mysql module:

    class { 'galera':
        override_options = {
            'mysqld' => {
                'bind_address' => '0.0.0.0',
            }
        }
        ...

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

* `additional_packages`: Specifies a list of additional packages that may be required for SST and other features. Valid options: an array. Default: A vendor-, version- and OS-specific value.
* `bind_address`: Specifies the IP address to bind MySQL/MariaDB to. The module expects the server to listen on localhost for proper operation. Valid options: a string. Default: `::`
* `bootstrap_command`: Specifies a command used to bootstrap the galera cluster. Valid options: a string. Default: A vendor-, version- and OS-specific bootstrap command.
* `client_package_name`: Specifies the name of the MySQL/MariaDB client package to install. Valid options: a string. Default: A vendor-, version- and OS-specific value.
* `configure_firewall`: Specifies wether to open firewall ports used by galera using puppetlabs-firewall. Valid options: `true` and `false`. Default: `true`
* `configure_repo`: Specifies wether to configure additional repositories that are requird for installing galera. Valid options: `true` and `false`. Default: `true`
* `create_root_my_cnf`: A flag to indicate if we should manage the root .my.cnf. Set this to false if you wish to manage your root .my.cnf file elsewhere. Valid options: `true` and `false`. Default: `true`
* `create_root_user`: A flag to indicate if we should manage the root user. Set this to false if you wish to manage your root user elsewhere. If this is set to undef, we will use true if galera_master == $::fqdn. Valid options: a string or undef. Default: `undef`
* `create_status_user`: A flag to indicate if we should manage the status user. Set this to false if you wish to manage your status user elsewhere. Valid options: `true` and `false`. Default: `true`
* `deb_sysmaint_password`: Specifies the password to set on Debian/Ubuntu for the sysmaint user used during updates. Valid options: a string. Default: `sysmaint`
* `default_options`: Internal parameter, *do NOT change!* Use `$override_options` to customize MySQL options.
* `galera_master`: Specifies the node that will bootstrap the cluster if all nodes go down. Valid options: a string. Default: `$fqdn`
* `galera_package_ensure`: Specifies the ensure state for the galera package. Note that some vendors do not allow installation of the wsrep-enabled MySQL/MariaDB and galera (arbitrator) on the same server. Valid options: all values supported by the package type. Default: `absent`
* `galera_package_name`: Specifies the name of the galera wsrep package to install. Valid options: a string. Default: A vendor-, version- and OS-specific value.
* `galera_servers`: Specifies a list of IP addresses of the nodes in the galera cluster. Valid options: an array. Default: `[${facts['networking']['ip']}]`
* `local_ip`: Specifies the IP address of this node to use for comms. Valid options: a string. Default: `$networking.ip`
* `manage_additional_packages`: Specifies wether additional packages should be installed that may be required for SST and other features. Valid options: `true` and `false`. Default: `true`
* `manage_package_nmap`: Specifies wether the package nmap should be installed. It is required for proper operation of this module. Valid options: `true` and `false`. Default: `true`
* `mysql_package_name`: Specifies the name of the server package to install. Valid options: a string. Default: A vendor-, version- and OS-specific value.
* `mysql_port`: Specifies the port to use for MySQL/MariaDB. Valid options: a string. Default: `3306`
* `mysql_restart`: Specifies the option to pass through to `mysql::server::restart`. This can cause issues during bootstrapping if switched on. Valid options: `true` and `false`. Default: `false`
* `mysql_service_name`: Specifies the option to pass through to `mysql::server`. Valid options: a string. Default: A vendor-, version- and OS-specific value.
* `override_options`: Specifies options to pass to `mysql::server` class. See the puppetlabs-mysql documentation for more information. Valid options: a hash. Default: `{}`
* `package_ensure`: Specifies the ensure state for packages. Valid options: all values supported by the package type. Default: `installed`
* `purge_conf_dir`: Specifies the option to pass through to `mysql::server`. Valid options:  `true` and `false`. Default: `true`
* `root_password`: Specifies the MySQL/MariaDB root password. Valid options: a string.
* `rundir`: Specifies the rundir for the MySQL/MariaDB service. Valid options: a string. Default: `/var/run/mysqld`
* `service_enabled`: Specifies wether the MySQL/MariaDB service should be enabled. Valid options: `true` and `false`. Default: `true`
* `status_allow`: Specifies the subnet or host(s) (in MySQL/MariaDB syntax) to allow status checks from. Valid options: a string. Default: `%`
* `status_available_when_donor`: Specifies wether the node will remain in the cluster when it enters donor mode. Valid options: `0` (remove), `1` (remain). Default: `0`
* `status_available_when_readonly`: When set to 0, clustercheck will return a "503 Service Unavailable" if the node is in the read_only state, as defined by the `read_only` MySQL/MariaDB variable. Values other than 0 have no effect. Valid options: an integer. Default: `-1`
* `status_check`: Specifies wether to configure a user and script that will check the status of the galera cluster. Valid options: `true` and `false`. Default: `true`
* `status_host`: Specifies the cluster to add the cluster check user to. Valid options: a string. Default: `localhost`
* `status_log_on_failure`: Specifies which fields xinetd will log on failure. Valid options: a string. Default: `undef`
* `status_log_on_success`: Specifies which fields xinetd will log on success. Valid options: a string. Default: `''`
* `status_log_on_success_operator`: Specifies which operator xinetd uses to output logs on success. Valid options: a string. Default: `=`
* `status_password`: Specifies the password of the status check user. Valid options: a string.
* `status_port`: Specifies the port for cluster check service. Valid options: an integer. Default: `9200`
* `status_user`: Specifies the name of the user to use for status checks. Valid options: a string: Default: `clustercheck`
* `validate_connection`: Specifies wether the module should ensure that the cluster can accept connections at the point where the `mysql::server` resource is marked as complete. This is used because after returning success, the service is still not quite ready. Valid options: `true` and `false`. Default: `true`
* `vendor_type`: Specifies the galera vendor to use. Valid options: codership, mariadb, percona. Default: `percona`
* `vendor_version`: Specifies the galera version to use. To avoid accidential updates, set this to the required version. Valid options: a string. Default: A vendor- and OS-specific value. (Usually the most recent version.)
* `vendor_version_internal`: Internal parameter, *do NOT change!*
* `wsrep_group_comm_port`: Specifies the port to use for galera clustering. Valid options: an integer. Default: `4567`
* `wsrep_inc_state_transfer_port`: Specifies the port to use for galera incremental state transfer. Valid options: an integer. Default: `4568`
* `wsrep_sst_auth`: Specifies the authentication information to use for SST. Valid options: a string. Default: `root:<%= $root_password %>`
* `wsrep_sst_method`: Specifies the method to use for state snapshot transfer between nodes. Valid options: mysqldump, rsync, skip, xtrabackup. Default: `rsync`
* `wsrep_state_transfer_port`: Specifies the port to use for galera state transfer. Valid options: an integer. Default: `4444`

#### Class: `galera::firewall`

Open firewall ports used by galera using puppetlabs-firewall.

* `source`: Specifies the firewall source addresses to unblock. Valid options: a string. Default: `undef`

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

* `action`: Specifies the MySQL/MariaDB command to run. Valid options: a string. Default: `select count(1);`
* `catch`: Specifies a string that if present indicates failure. Valid options: a string. Default: `ERROR`
* `delay`: Specifies the seconds to sleep between attempts. Valid options: an integer: Default: `3`
* `host`: Specifies the MySQL/MariaDB host to check. Valid options: a string. Default: `$galera::status_host`
* `inv_catch`: Specifies a string that if not present indicates failure. Valid options: a string. Default: `undef`
* `password`: Specifies the password for the MySQL/MariaDB user. Valid options: a string. Default: `$galera::status_password`
* `retries`: Specifies the number of times to retry connection. Valid options: an integer. Default: `20`
* `user`: Specifies the MySQL/MariaDB user to use. Valid options: a string. Default: `$galera::status_user`

## Limitations

This module was created to work in tandem with the puppetlabs-mysql module, rather than replacing it. As the stages in the mysql module are quite strictly laid out in the `mysql::server` class, this module places its own resources in the gaps between them.

Of note is an `exec` that will start the mysql service with parameters which will bootstrap/start a new cluster, but only if it cannot open the comms port to any other node in the provided list. This is done with a simple `nc` command and should not be considered terribly reliable.

Furthermore the bootstrap functionality may be considered harmful. A better approach is currently being discussed and will be included in a future release ([GH-116](https://github.com/fraenki/puppet-galera/issues/116)).

## Development

### Contributing

Please use the GitHub issues functionality to report any bugs or requests for new features. Feel free to fork and submit pull requests for potential contributions.
