# @summary Adds workarounds to solve issues specific to Debian-based systems.
# @api private
class galera::debian {
  if ($galera::arbitrator == false) {
    # puppetlabs-mysql now places config before installing the package, which
    # causes issues if the service is started as part of package installs, as
    # it is on Debian/Ubuntu. Resolve this by putting a default my.cnf in place
    # before installing the package, then putting the real config file back
    # after installing the package but before starting the service for real.
    # Also use a temporary dbdir, because Galera will refuse to initialize if
    # this directory is not empty.
    file { '/var/lib/mysql-install-tmp':
      ensure  => directory,
      owner   => 'root',
      group   => 'root',
      mode    => '0777',
      require => Class['mysql::server::config'],
    }
    ~> file { '/etc/mysql/puppet_debfix.cnf':
      ensure  => present,
      owner   => 'root',
      group   => 'root',
      content => epp('galera/debian_default_my_cnf.epp'),
      require => Class['mysql::server::config'],
    }
    ~> exec { 'fix_galera_config_errors_episode_I':
      command     => 'mv -f /etc/mysql/my.cnf /tmp/my.cnf && cp -f /etc/mysql/puppet_debfix.cnf /etc/mysql/my.cnf',
      path        => '/usr/bin:/bin:/usr/sbin:/sbin',
      refreshonly => true,
    }
    ~> exec { 'fix_galera_config_errors_episode_II':
      command     => 'cp -f /tmp/my.cnf /etc/mysql/my.cnf',
      path        => '/usr/bin:/bin:/usr/sbin:/sbin',
      refreshonly => true,
      require     => Class['mysql::server::install'],
      before      => Class['mysql::server::installdb'],
    }
    ~> exec { 'fix_galera_config_errors_episode_III':
      command     => 'rm -rf /var/lib/mysql-install-tmp',
      path        => '/usr/bin:/bin:/usr/sbin:/sbin',
      refreshonly => true,
    }
    ~> exec { 'fix_galera_config_errors_episode_IV':
      # puppetlabs-mysql uses /var/lib/mysql as *datadir*, but the postinst
      # script of codership package mysql-wsrep-server assumes that
      # /var/lib/mysql is the *statedir* and creates the flag file inside the
      # datadir.
      # This causes the bootstrap/initialization to fail, so we have to remove
      # this flag file first.
      command     => 'rm -f /var/lib/mysql/debian-*.flag',
      path        => '/usr/bin:/bin:/usr/sbin:/sbin',
      refreshonly => true,
    }

    # Debian policy will autostart the non galera mysql after
    # package install, so kill it if the package is
    # installed during this puppet run
    exec { 'clean_up_ubuntu':
      command     => 'service mysql stop',
      path        => '/usr/bin:/bin:/usr/sbin:/sbin',
      refreshonly => true,
      subscribe   => Package['mysql-server'],
      before      => Class['mysql::server::installdb'],
      require     => Class['mysql::server::install'],
    }

    if ($::fqdn == $galera::galera_master) {
      # Debian sysmaint pw will be set on the master,
      # and needs to be consistent across the cluster.
      mysql_user { 'debian-sys-maint@localhost':
        ensure        => 'present',
        password_hash => mysql_password($galera::deb_sysmaint_password),
        provider      => 'mysql',
      }
      if $galera::create_root_my_cnf {
        Exec['create .my.cnf for user root'] -> Mysql_user['debian-sys-maint@localhost']
      }

      mysql_grant { 'debian-sys-maint@localhost/*.*':
        ensure     => 'present',
        options    => ['GRANT'],
        privileges => ['ALL'],
        table      => '*.*',
        user       => 'debian-sys-maint@localhost',
      }

      file { '/etc/mysql/debian.cnf':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0600',
        content => epp('galera/debian.cnf.epp'),
        require => Mysql_user['debian-sys-maint@localhost'],
      }
    } else {
      # Ensure this file is changed only after stopping the service or
      # said service stop operation will fail
      file { '/etc/mysql/debian.cnf':
        ensure  => present,
        owner   => 'root',
        group   => 'root',
        mode    => '0600',
        content => epp('galera/debian.cnf.epp'),
        require => Exec['clean_up_ubuntu'],
        before  => Service[$galera::mysql_service_name],
      }
    }

    # Ensure mysql server is installed before writing debian.cnf, since the
    # package will create /etc/mysql
    Package['mysql-server'] -> File['/etc/mysql/debian.cnf']
  }
}
