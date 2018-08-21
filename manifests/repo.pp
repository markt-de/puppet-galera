# Class galera::repo
#
# Installs the appropriate repositories from which percona packages
# can be installed
#
class galera::repo(
  Boolean $apt_codership_repo_include_src,
  String $apt_codership_repo_key,
  String $apt_codership_repo_key_server,
  String $apt_codership_repo_location,
  String $apt_codership_repo_release,
  String $apt_codership_repo_repos,
  Boolean $apt_mariadb_repo_include_src,
  String $apt_mariadb_repo_key,
  String $apt_mariadb_repo_key_server,
  String $apt_mariadb_repo_location,
  String $apt_mariadb_repo_release,
  String $apt_mariadb_repo_repos,
  Boolean $apt_percona_repo_include_src,
  String $apt_percona_repo_key,
  String $apt_percona_repo_key_server,
  String $apt_percona_repo_location,
  String $apt_percona_repo_release,
  String $apt_percona_repo_repos,
  Boolean $epel_needed,
  String $repo_vendor,
  String $yum_codership_baseurl,
  String $yum_codership_descr,
  Integer $yum_codership_enabled,
  Integer $yum_codership_gpgcheck,
  String $yum_codership_gpgkey,
  String $yum_mariadb_descr,
  Integer $yum_mariadb_enabled,
  Integer $yum_mariadb_gpgcheck,
  String $yum_mariadb_gpgkey,
  String $yum_percona_baseurl,
  String $yum_percona_descr,
  Integer $yum_percona_enabled,
  Integer $yum_percona_gpgcheck,
  String $yum_percona_gpgkey,
  Optional[String] $yum_mariadb_baseurl,
) {
  case $::osfamily {
    'Debian': {
      if ($::operatingsystem == 'Ubuntu') or ($::operatingsystem == 'Debian') {
        if ($repo_vendor == 'percona') {
          apt::source { 'galera_percona_repo':
            location => $apt_percona_repo_location,
            release  => $apt_percona_repo_release,
            repos    => $apt_percona_repo_repos,
            key      => {
              'id'     => $apt_percona_repo_key,
              'server' => $apt_percona_repo_key_server,
            },
            include  => {
              'src' => $apt_percona_repo_include_src,
            },
          }
        } elsif ($repo_vendor == 'mariadb') {
          apt::source { 'galera_mariadb_repo':
            location => $apt_mariadb_repo_location,
            release  => $apt_mariadb_repo_release,
            repos    => $apt_mariadb_repo_repos,
            key      => {
              'id'     => $apt_mariadb_repo_key,
              'server' => $apt_mariadb_repo_key_server,
            },
            include  => {
              'src' => $apt_mariadb_repo_include_src,
            },
          }
        } elsif ($repo_vendor == 'codership') {
          apt::source { 'galera_codership_repo':
            location => $apt_codership_repo_location,
            release  => $apt_codership_repo_release,
            repos    => $apt_codership_repo_repos,
            key      => {
              'id'     => $apt_codership_repo_key,
              'server' => $apt_codership_repo_key_server,
            },
            include  => {
              'src' => $apt_codership_repo_include_src,
            },
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
          descr    => $yum_percona_descr,
          baseurl  => $yum_percona_baseurl,
          gpgkey   => $yum_percona_gpgkey,
          enabled  => $yum_percona_enabled,
          gpgcheck => $yum_percona_gpgcheck,
        } -> package {'Percona-Server-shared-compat':
      }

        if $epel_needed {
          # Needed for socat package
          yumrepo { 'epel':
            mirrorlist     => "http://mirrors.fedoraproject.org/mirrorlist?repo=epel-${::os_maj_version}&arch=${::architecture}",
            baseurl        => 'absent',
            failovermethod => 'priority',
            enabled        => '1',
            gpgcheck       => '1',
            gpgkey         => 'https://fedoraproject.org/static/0608B895.txt'
          }
        }
      }
      elsif $repo_vendor == 'mariadb' {
        yumrepo { 'mariadb':
          descr    => $yum_mariadb_descr,
          enabled  => $yum_mariadb_enabled,
          gpgcheck => $yum_mariadb_gpgcheck,
          gpgkey   => $yum_mariadb_gpgkey,
          baseurl  => $yum_mariadb_baseurl
        }
        include galera::mariadb
      }
      elsif $repo_vendor == 'codership' {
        yumrepo { 'codership':
          descr    => $yum_codership_descr,
          enabled  => $yum_codership_enabled,
          gpgcheck => $yum_codership_gpgcheck,
          gpgkey   => $yum_codership_gpgkey,
          baseurl  => $yum_codership_baseurl
        }
      }
    }
    default: {
      fail('This distribution is not currently supported by the galera module')
    }
  }
}
