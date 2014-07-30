# Class galera::repo

# Installs the appropriate repositories from which percona packages
# can be installed

class galera::repo(
  $repo_vendor = $galera::vendor_type,
  $epel_needed = true,

  # Ubuntu/percona
  $apt_percona_repo_location = 'http://repo.percona.com/apt/',
  $apt_percona_repo_release = $::lsbdistcodename,
  $apt_percona_repo_repos = 'main',
  $apt_percona_repo_key = '1C4CBDCDCD2EFD2A',
  $apt_percona_repo_key_server = 'keys.gnupg.net',
  $apt_percona_repo_include_src = false,

  # Ubuntu/mariadb
  $apt_mariadb_repo_location = 'http://mirror.aarnet.edu.au/pub/MariaDB/repo/5.5/ubuntu',
  $apt_mariadb_repo_release = $::lsbdistcodename,
  $apt_mariadb_repo_repos = 'main',
  $apt_mariadb_repo_key = '1BB943DB',
  $apt_mariadb_repo_key_server = 'keys.gnupg.net',
  $apt_mariadb_repo_include_src = false,

  #RedHat/percona
  $yum_percona_descr = "CentOS ${::operatingsystemmajrelease} - Percona",
  $yum_percona_baseurl = "http://repo.percona.com/centos/${::operatingsystemmajrelease}/os/${::architecture}/",
  $yum_percona_gpgkey = 'http://www.percona.com/downloads/percona-release/RPM-GPG-KEY-percona',
  $yum_percona_enabled = 1,
  $yum_percona_gpgcheck = 1,

  #RedHat/mariadb
  $yum_mariadb_descr = 'MariaDB Yum Repo',
  $yum_mariadb_enabled = 1,
  $yum_mariadb_gpgcheck = 1,
  $yum_mariadb_gpgkey = 'https://yum.mariadb.org/RPM-GPG-KEY-MariaDB',
  $yum_mariadb_baseurl = undef
) {
  include ::galera::params

  if ! $yum_mariadb_baseurl {
    $lower = downcase($::operatingsystem)
    $real_yum_mariadb_baseurl = "http://yum.mariadb.org/5.5.35-upd/${lower}${::operatingsystemmajrelease}-amd64"
  } else {
    $real_yum_mariadb_baseurl = $yum_mariadb_baseurl
  }

  case $::osfamily {
    'Debian': {
      if $::operatingsystem == 'Ubuntu' {
        if ($repo_vendor == 'percona') {
          apt::source { 'galera_percona_repo':
            location          => $apt_percona_repo_location,
            release           => $apt_percona_repo_release,
            repos             => $apt_percona_repo_repos,
            key               => $apt_percona_repo_key,
            key_server        => $apt_percona_repo_key_server,
            include_src       => $apt_percona_repo_include_src,
          }
        } elsif ($repo_vendor == 'mariadb') {
          apt::source { 'galera_mariadb_repo':
            location          => $apt_mariadb_repo_location,
            release           => $apt_mariadb_repo_release,
            repos             => $apt_mariadb_repo_repos,
            key               => $apt_mariadb_repo_key,
            key_server        => $apt_mariadb_repo_key_server,
            include_src       => $apt_mariadb_repo_include_src,
          }
        }
      }
      if ($repo_vendor == 'osp5') {
        fail('OSP5 is only supported on RHEL platforms.')
      }
    }

    'RedHat': {
      if $repo_vendor == 'percona' {
        yumrepo { 'percona':
          descr     => $yum_percona_descr,
          baseurl   => $yum_percona_baseurl,
          gpgkey    => $yum_percona_gpgkey,
          enabled   => $yum_percona_enabled,
          gpgcheck  => $yum_percona_gpgcheck,
        } -> package {'Percona-Server-shared-compat':
      }

        if $epel_needed {
          # Needed for socat package
          yumrepo { 'epel':
            mirrorlist      => "http://mirrors.fedoraproject.org/mirrorlist?repo=epel-${::os_maj_version}&arch=${::architecture}",
            baseurl         => 'absent',
            failovermethod  => 'priority',
            enabled         => '1',
            gpgcheck        => '1',
            gpgkey          => 'https://fedoraproject.org/static/0608B895.txt'
          }
        }
      }
      elsif $repo_vendor == 'mariadb' {
        yumrepo { 'mariadb':
          descr     => $yum_mariadb_descr,
          enabled   => $yum_mariadb_enabled,
          gpgcheck  => $yum_mariadb_gpgcheck,
          gpgkey    =>  $yum_mariadb_gpgkey,
          baseurl   => $real_yum_mariadb_baseurl
        }
      }
    }
    default: {
      fail('This distribution is not currently supported by the galera module')
    }
  }
}
