# Class galera::repo
#
# Installs the appropriate repositories from which galera packages
# can be installed
#
class galera::repo(
  # required parameters
  String $vendor_type = $galera::vendor_type,
  Boolean $epel_needed,
  # optional parameters
  Optional[String] $vendor_version = undef,
  Optional[Array] $additional_packages = undef,
  # APT
  Optional[Boolean] $apt_include_src = undef,
  Optional[String] $apt_key = undef,
  Optional[String] $apt_key_server = undef,
  Optional[String] $apt_location = undef,
  Optional[String] $apt_release = undef,
  Optional[String] $apt_repos = undef,
  # YUM
  Optional[String] $yum_baseurl = undef,
  Optional[String] $yum_descr = undef,
  Optional[Integer] $yum_enabled = undef,
  Optional[Integer] $yum_gpgcheck = undef,
  Optional[String] $yum_gpgkey = undef,
) {
  # Fetch appropiate default values from module data, depending on the values
  # of $vendor_type and $vendor_version.
  # XXX: Originally this was supposed to take place when evaluating the class
  # parameters. Now this is basically an ugly compatibility layer to support
  # overriding parameters in non-hiera configurations (where solely relying
  # on lookup() simply does not work). Should be refactored when a better
  # solution is available.
  if !$vendor_version {
    $vendor_version_real = lookup("${module_name}::${vendor_type}::default_version")
  } else { $vendor_version_real = $vendor_version }
  $vendor_version_internal = regsubst($vendor_version_real, '\.', '', 'G')

  # The following compatibility layer (part 2) is only required for parameters
  # that may vary depending on the values of $vendor_version and $vendor_type.
  $params = {
    apt_include_src => $apt_include_src,
    apt_key => $apt_key,
    apt_key_server => $apt_key_server,
    apt_location => $apt_location,
    apt_release => $apt_release,
    apt_repos => $apt_repos,
    yum_baseurl => $yum_baseurl,
    yum_descr => $yum_descr,
    yum_enabled => $yum_enabled,
    yum_gpgcheck => $yum_gpgcheck,
    yum_gpgkey => $yum_gpgkey,
  }.reduce({}) |$memo, $x| {
    # If a value was specified as class parameter, then use it. Otherwise use
    # lookup() to find a value in Hiera (or to fallback to default values from
    # module data).
    if !$x[1] {
      $_v = lookup("${name}::${vendor_type}_${vendor_version_internal}_${$x[0]}", {default_value => undef}) ? {
        undef => lookup("${name}::${vendor_type}_${$x[0]}"),
        default => lookup("${name}::${vendor_type}_${vendor_version_internal}_${$x[0]}"),
      }
    } else {
      $_v = $x[1]
    }
    $memo + {$x[0] => $_v}
  }

  case $facts['os']['family'] {
    'Debian': {
      if ($vendor_type == 'osp5') {
        fail('OSP5 is only supported on RHEL platforms.')
      }
      apt::source { "${module_name}_${vendor_type}":
        location => inline_epp($params['apt_location']),
        release  => $params['apt_release'],
        repos    => $params['apt_repos'],
        key      => {
          'id'     => $params['apt_key'],
          'server' => $params['apt_key_server'],
        },
        include  => {
          'src' => $params['apt_include_src'],
        },
      }
    }
    'RedHat': {
      yumrepo { "${module_name}_${vendor_type}":
        descr    => $params['yum_descr'],
        baseurl  => inline_epp($params['yum_baseurl']),
        gpgkey   => $params['yum_gpgkey'],
        enabled  => $params['yum_enabled'],
        gpgcheck => $params['yum_gpgcheck'],
      }

      if $epel_needed {
        # Needed for socat package
        yumrepo { "${module_name}_epel":
          # FIXME: replace hardcoded values, specify includepkgs parameter
          mirrorlist     => "https://mirrors.fedoraproject.org/metalink?repo=epel-${facts['os']['release']['major']}&arch=${facts['os']['architecture']}",
          baseurl        => 'absent',
          failovermethod => 'priority',
          enabled        => '1',
          gpgcheck       => '1',
          gpgkey         => "https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-${facts['os']['release']['major']}"
        }
      }
    }
    default: {
      fail("Operating system ${facts['os']['family']} is not currently supported")
    }
  }

  # Fetch additional packages that may be required for this vendor/version.
  if !$additional_packages {
    $additional_packages_real = lookup("${module_name}::${vendor_type}::${vendor_version_internal}::additional_packages", {default_value => undef}) ? {
      undef => lookup("${module_name}::${vendor_type}::additional_packages", {default_value => undef}),
      default => lookup("${module_name}::${vendor_type}::${vendor_version_internal}::additional_packages", {default_value => undef}),
    }
  } else { $additional_packages_real = $additional_packages}

  if $additional_packages_real {
    ensure_packages($additional_packages_real)
  }
}
