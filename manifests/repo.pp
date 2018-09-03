# Class galera::repo
#
# Installs the appropriate repositories from which galera packages
# can be installed
#
class galera::repo(
  # parameters that need to be evaluated early
  String $vendor_type = $galera::vendor_type,
  String $vendor_version = $galera::vendor_version,
  String $vendor_version_internal = regsubst($vendor_version, '\.', '', 'G'),
  # APT
  Boolean $apt_repo_include_src = lookup("${module_name}::repo::apt_${vendor_type}_${vendor_version_internal}_include_src", {default_value => undef}) ? {
    undef => lookup("${module_name}::repo::apt_${vendor_type}_include_src"),
    default => lookup("${module_name}::repo::apt_${vendor_type}_${vendor_version_internal}_include_src"),
  },
  String $apt_key = lookup("${module_name}::repo::apt_${vendor_type}_${vendor_version_internal}_key", {default_value => undef}) ? {
    undef => lookup("${module_name}::repo::apt_${vendor_type}_key"),
    default => lookup("${module_name}::repo::apt_${vendor_type}_${vendor_version_internal}_key"),
  },
  String $apt_key_server  = lookup("${module_name}::repo::apt_${vendor_type}_${vendor_version_internal}_key_server", {default_value => undef}) ? {
    undef => lookup("${module_name}::repo::apt_${vendor_type}_key_server"),
    default => lookup("${module_name}::repo::apt_${vendor_type}_${vendor_version_internal}_key_server"),
  },
  String $apt_location = lookup("${module_name}::repo::apt_${vendor_type}_${vendor_version_internal}_location", {default_value => undef}) ? {
    undef => lookup("${module_name}::repo::apt_${vendor_type}_location"),
    default => lookup("${module_name}::repo::apt_${vendor_type}_${vendor_version_internal}_location"),
  },
  String $apt_release = lookup("${module_name}::repo::apt_${vendor_type}_${vendor_version_internal}_release", {default_value => undef}) ? {
    undef => lookup("${module_name}::repo::apt_${vendor_type}_release"),
    default => lookup("${module_name}::repo::apt_${vendor_type}_${vendor_version_internal}_release"),
  },
  String $apt_repos = lookup("${module_name}::repo::apt_${vendor_type}_${vendor_version_internal}_repos", {default_value => undef}) ? {
    undef => lookup("${module_name}::repo::apt_${vendor_type}_repos"),
    default => lookup("${module_name}::repo::apt_${vendor_type}_${vendor_version_internal}_repos"),
  },
  # YUM
  Boolean $epel_needed,
  String $yum_baseurl = lookup("${module_name}::repo::yum_${vendor_type}_${vendor_version_internal}_baseurl", {default_value => undef}) ? {
    undef => lookup("${module_name}::repo::yum_${vendor_type}_baseurl"),
    default => lookup("${module_name}::repo::yum_${vendor_type}_${vendor_version_internal}_baseurl"),
  },
  String $yum_descr = lookup("${module_name}::repo::yum_${vendor_type}_${vendor_version_internal}_descr", {default_value => undef}) ? {
    undef => lookup("${module_name}::repo::yum_${vendor_type}_descr"),
    default => lookup("${module_name}::repo::yum_${vendor_type}_${vendor_version_internal}_descr"),
  },
  Integer $yum_enabled = lookup("${module_name}::repo::yum_${vendor_type}_${vendor_version_internal}_enabled", {default_value => undef}) ? {
    undef => lookup("${module_name}::repo::yum_${vendor_type}_enabled"),
    default => lookup("${module_name}::repo::yum_${vendor_type}_${vendor_version_internal}_enabled"),
  },
  Integer $yum_gpgcheck = lookup("${module_name}::repo::yum_${vendor_type}_${vendor_version_internal}_gpgcheck", {default_value => undef}) ? {
    undef => lookup("${module_name}::repo::yum_${vendor_type}_gpgcheck"),
    default => lookup("${module_name}::repo::yum_${vendor_type}_${vendor_version_internal}_gpgcheck"),
  },
  String $yum_gpgkey = lookup("${module_name}::repo::yum_${vendor_type}_${vendor_version_internal}_gpgkey", {default_value => undef}) ? {
    undef => lookup("${module_name}::repo::yum_${vendor_type}_gpgkey"),
    default => lookup("${module_name}::repo::yum_${vendor_type}_${vendor_version_internal}_gpgkey"),
  },
) {
  case $facts['os']['family'] {
    'Debian': {
      if ($vendor_type == 'osp5') {
        fail('OSP5 is only supported on RHEL platforms.')
      }
      apt::source { "${module_name} ${vendor_type} repository":
        location => $apt_location,
        release  => $apt_release,
        repos    => $apt_repos,
        key      => {
          'id'     => $apt_key,
          'server' => $apt_server,
        },
        include  => {
          'src' => $apt_include_src,
        },
      }
    }
    'RedHat': {
      yumrepo { "${module_name} ${vendor_type} repository":
        descr    => $yum_descr,
        baseurl  => $yum_baseurl,
        gpgkey   => $yum_gpgkey,
        enabled  => $yum_enabled,
        gpgcheck => $yum_gpgcheck,
      }

      if $epel_needed {
        # Needed for socat package
        yumrepo { "${module_name} epel repository":
          mirrorlist     => "https://mirrors.fedoraproject.org/metalink?repo=epel-${facts['os']['release']['major']}&arch=${facts['os']['architecture']}",
          baseurl        => 'absent',
          failovermethod => 'priority',
          enabled        => '1',
          gpgcheck       => '1',
          gpgkey         => "https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-${facts['os']['release']['major']}"
        }
      }

      if $vendor_type == 'mariadb' {
        include galera::mariadb
      }
      elsif $vendor_type == 'percona' {
        package {'Percona-Server-shared-compat':}
      }
    }
    default: {
      fail("Operating system ${facts['os']['family']} is not currently supported")
    }
  }
}
