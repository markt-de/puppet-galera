# == Class galera
#
# Installs mysql with galera
#
# === Parameters
#
# [*galera_servers*]
#   (optional) A list of IP addresses of the nodes in
#   the galera cluster
#   Defaults to [$::ipaddress_eth1]
#
# [*galera_master*]
#   (optional) The node that will bootstrap the cluster if
#   all nodes go down. (There is no election)
#   Defaults to $::fqdn
#
# [*local_ip*]
#   (optional) The IP address of this node to use for comms
#   Defaults to $::ipaddress_eth1
#
# [*bind_address*]
#   (optional) The IP address to bind mysql to
#   Defaults to $::ipaddress_eth1
#
# [*mysql_port*]
#   (optional) The port to use for mysql
#   Defaults to 3306
#
# [*wsrep_group_comm_port*]
#   (optional) The port to use for galera clsutering
#   Defaults to 4567
#
# [*wsrep_state_transfer_port*]
#   (optional) The port to use for galera state transfer
#   Defaults to 4444
#
# [*wsrep_inc_state_transfer_port*]
#   (optional) The port to use for galera incremental
#   state transfer
#   Defaults to 4568
#
# [*wsrep_sst_method*]
#   (optional) The method to use for state snapshot transfer
#   between nodes
#   Defaults to rsync
#   xtrabackup, xtrabackup-v2, mysqldump, and skip options are also
#   accepted
#   Note that rsync 3.10 is incompatible with Percona XtraDB 5.5
#   currently (see launchpad bug #1315528). xtrabackup-v2 is the
#   recommended solution when using Percona XtraDB on platforms such as
#   Ubuntu trusty which provide rsync 3.10
#
# [*root_password*]
#   (optional) The mysql root password.
#   Defaults to 'test'
#
# [*override_options*]
#   (optional) Options to pass to mysql::server class.
#   See the puppet-mysql doc for more information.
#   Defaults to {}
#
# [*vendor_type*]
#   (optional) The galera vendor to use. Valid options
#   are 'mariadb' and 'percona'
#   Defaults to 'percona'
#
# [*configure_repo*]
#   (optional) Whether to configure additional repositories for
#   installing galera
#   Defaults to true
#
# [*configure_firewall*]
#   (optional) Whether to open firewall ports used by galera
#   Defaults to true
#
# [*deb_sysmaint_password*]
#   (optional) The password to set on Debian for the sysmaint
#   user used during updates.
#   Defaults to 'sysmaint'
#
# [*mysql_restart*]
#   (optional) The option to pass through to mysql::server::restart
#   This can cause issues during bootstrapping if switched on.
#   Defaults to false
#
# [*mysql_package_name*]
#   (optional) The name of the server package to install.  The default is
#   platform and vendor dependent.
#
# [*galera_package_name*]
#   (optional) The name of the galera wsrep package to install.  The default is
#   platform and vendor dependent.
#
# [*client_package_name*]
#   (optional) The name of the mysql client package.  The default is platform
#   and vendor dependent.
#
class galera(
  $galera_servers                   = [$::ipaddress_eth1],
  $galera_master                    = $::fqdn,
  $local_ip                         = $::ipaddress_eth1,
  $bind_address                     = $::ipaddress_eth1,
  $mysql_port                       = 3306,
  $wsrep_group_comm_port            = 4567,
  $wsrep_state_transfer_port        = 4444,
  $wsrep_inc_state_transfer_port    = 4568,
  $wsrep_sst_method                 = 'rsync',
  $root_password                    = 'test',
  $override_options                 = {},
  $vendor_type                      = 'percona',
  $configure_repo                   = true,
  $configure_firewall               = true,
  $deb_sysmaint_password            = 'sysmaint',
  $validate_connection              = true,
  $status_check                     = true,
  $mysql_restart                    = false,
  $mysql_package_name               = undef,
  $galera_package_name              = undef,
  $client_package_name              = undef,
)
{
  if $configure_repo {
    include galera::repo
    Class['::galera::repo'] -> Class['mysql::server']
  }

  if $configure_firewall {
    include galera::firewall
  }

  # Debian machines need some help
  if ($::osfamily == 'Debian') {
    include galera::debian
  }

  if $status_check {
    include galera::status
  }

  if $validate_connection {
    include galera::validate
  }

  include galera::params

  $options = mysql_deepmerge($galera::params::default_options, $override_options)

  if $::fqdn != $galera_master {

    File<| title == "${::root_home}/.my.cnf" |> {
      require => Class['mysql::server::service'],
      before => Class['mysql::server::providers']
    }

    Mysql_user<| title == 'root@localhost' |> {
      require => File["${::root_home}/.my.cnf"]
    }

    exec { 'wait_for_galera_master':
      command => "bash -c \"while [ 1 ]; do nc -z ${galera_master} ${wsrep_group_comm_port}; if [ \$? -eq 0 ]; then break; fi; sleep 3; done; sleep 30\"",
      timeout  => 900,	# 15 minutes
      before   => [Class['mysql::server::service'], Service['mysqld']],
      require  => Package[$galera::params::nc_package_name],
      path     => '/usr/bin:/bin:/usr/sbin:/sbin',
    }
  }

  if $::fqdn == $galera_master {
    $temp_root_password = $root_password
  } else {
    $temp_root_password = 'UNSET'
  }

  class { 'mysql::server':
    package_name        => $galera::params::mysql_package_name,
    override_options    => $options,
    root_password       => $temp_root_password,
    service_name        => $galera::params::mysql_service_name,
    restart             => $mysql_restart,
  }

  file { $galera::params::rundir:
    ensure  => directory,
    owner   => 'mysql',
    group   => 'mysql',
    require => Class['mysql::server::install'],
    before  => Class['mysql::server::config']
  }

  if $galera::params::additional_packages {
    package{ $galera::params::additional_packages:
      ensure    => installed,
      require   => Anchor['mysql::server::start'],
      before    => Class['mysql::server::install']
    }
  }

  Package<| title == 'mysql_client' |> {
    name => $galera::params::client_package_name
  }

  if $galera::params::rhel_mysql_client_repo_hack == true and $::fqdn == $galera_master {
    class { 'mysql::client': }

    Yumrepo['mariadb'] -> Class['mysql::client']

    Class['mysql::client'] -> Mysql_user['root@localhost']
  }

  package{[
      $galera::params::nc_package_name,
      $galera::params::galera_package_name,
      ] :
    ensure  => installed,
    require => Anchor['mysql::server::start'],
    before  => Class['mysql::server::install']
  }


  if $::fqdn == $galera_master {
    # If there are no other servers up and we are the master, the cluster
    # needs to be bootstrapped. This happens before the service is managed
    $server_list = join($galera_servers, ' ')
    exec { 'bootstrap_galera_cluster':
      command   => $galera::params::bootstrap_command,
      require   => Class['mysql::server::config'],
      before    => [Class['mysql::server::service'], Service['mysqld']],
      provider  => shell,
      path      => '/usr/bin:/bin:/usr/sbin:/sbin'
    }

  }
}
