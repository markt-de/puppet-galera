# @summary Evaluates which repositories should be enabled depending on $vendor_type and $vendor_version.
# @api private
#
class galera::repo(
  # required parameters
  Boolean $epel_needed,
  # optional parameters
  Optional[Array] $additional_packages = undef,
) {
  # Adjust $vendor_version for use with lookup()
  if !$galera::vendor_version {
    $vendor_version_real = lookup("${module_name}::${galera::vendor_type}::default_version")
  } else { $vendor_version_real = $galera::vendor_version }
  $vendor_version_internal = regsubst($vendor_version_real, '\.', '', 'G')

  # Adjust $wsrep_sst_method for use with lookup()
  $wsrep_sst_method_internal = regsubst($galera::wsrep_sst_method, '-', '_', 'G')

  # Get the value of $want_repos from all possible sources:
  #   galera::sst::SSTMETHOD::VENDOR::VERSION::want_repos
  #   galera::sst::SSTMETHOD::want_repos
  #   galera::VENDOR::VERSION::want_repos
  #   galera::VENDOR::want_repos
  if (!defined('$galera::override_repos') or empty($galera::override_repos)) {
    # Lookup required repos for the selected vendor.
    $_vendor_tmp = lookup("${module_name}::${galera::vendor_type}::${vendor_version_internal}::want_repos", {default_value => undef}) ? {
      undef => lookup("${module_name}::${galera::vendor_type}::want_repos", {default_value => []}),
      default => lookup("${module_name}::${galera::vendor_type}::${vendor_version_internal}::want_repos")
    }
    # Ensure that we got an Array, silently drop everything else.
    if ($_vendor_tmp =~ Array) {
      $repos_vendor = $_vendor_tmp
    } else {
      $repos_vendor = []
    }

    # Lookup required repos for the selected SST method.
    if ($galera::arbitrator) {
      # Skip lookup, because Arbitrator does not use SST.
      $_sst_tmp = []
    } else {
      $_sst_tmp = lookup("${module_name}::sst::${wsrep_sst_method_internal}::${galera::vendor_type}::${vendor_version_internal}::want_repos", {default_value => undef}) ? {
        undef => lookup("${module_name}::sst::${wsrep_sst_method_internal}::want_repos", {default_value => []}),
        default => lookup("${module_name}::sst::${wsrep_sst_method_internal}::${galera::vendor_type}::${vendor_version_internal}::want_repos")
      }
    }
    # Ensure that we got an Array, silently drop everything else.
    if ($_sst_tmp =~ Array) {
      $repos_sst = $_sst_tmp
    } else {
      $repos_sst = []
    }

    # Merge repos from both sources and make them unique.
    $repos = ($repos_vendor + $repos_sst).unique
  } else {
    # Always prefer user-specified repos.
    $repos = $galera::override_repos
  }

  # Finally setup repositories
  $repos.each |$repo| {
    galera::repo::config { $repo: }
  }

  case $facts['os']['family'] {
    'RedHat': {
      if $epel_needed {
        # Needed for socat package
        yumrepo { "${module_name}_epel":
          mirrorlist     => "https://mirrors.fedoraproject.org/metalink?repo=epel-${facts['os']['release']['major']}&arch=${facts['os']['architecture']}",
          baseurl        => 'absent',
          failovermethod => 'priority',
          enabled        => '1',
          gpgcheck       => '1',
          gpgkey         => "https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-${facts['os']['release']['major']}"
        }
      }
    }
    default: { }
  }

  # Fetch additional packages that may be required for this vendor/version.
  if !$additional_packages {
    $additional_packages_real = lookup("${module_name}::${galera::vendor_type}::${vendor_version_internal}::additional_packages", {default_value => undef}) ? {
      undef => lookup("${module_name}::${galera::vendor_type}::additional_packages", {default_value => undef}),
      default => lookup("${module_name}::${galera::vendor_type}::${vendor_version_internal}::additional_packages", {default_value => undef}),
    }
  } else { $additional_packages_real = $additional_packages}

  if $additional_packages_real {
    ensure_packages($additional_packages_real)
  }
}
