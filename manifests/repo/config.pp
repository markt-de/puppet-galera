# @summary Configures a APT or YUM repository.
# @api private
#
# @param repo
#  Specifies the name of the repository that should be configured (namevar).
#
define galera::repo::config (
  String $repo = $title,
) {
  # Adjust $vendor_version for use with lookup() and inline_epp()
  if !$galera::vendor_version {
    $vendor_version_real = lookup("${module_name}::${galera::vendor_type}::default_version")
  } else { $vendor_version_real = $galera::vendor_version }
  $vendor_version_internal = regsubst($vendor_version_real, '\.', '', 'G')

  # Prepare $wsrep_sst_method for use with inline_epp()
  $wsrep_sst_method_internal = regsubst($galera::wsrep_sst_method, '-', '_', 'G')

  # Evaluate type of repository for lookup().
  case $facts['os']['family'] {
    'Debian': { $type = 'apt' }
    'RedHat': { $type = 'yum' }
    default: {
      fail("Repo management for operating system ${facts['os']['family']} is not currently supported.")
    }
  }

  # Lookup the repo config from all possible sources:
  #   galera::repo::REPONAME::VENDOR::VERSION::TYPE
  #   galera::repo::REPONAME::TYPE
  # The most specific configuration wins.
  $_config_tmp = lookup("${module_name}::repo::${repo}::${galera::vendor_type}::${vendor_version_internal}::${type}", {default_value => undef}) ? {
    undef => lookup("${module_name}::repo::${repo}::${type}", {default_value => undef}),
    default => lookup("${module_name}::repo::${repo}::${galera::vendor_type}::${vendor_version_internal}::${type}")
  }
  if !($_config_tmp =~ Hash) {
    fail("Config for repo ${repo} does not exist or is not a Hash.")
  }

  # The following allows for extremely flexible repo configurations.
  # By passing all options to inline_epp() any variable/parameter that is
  # available in Puppet code can be used (provided that the repo option uses
  # epp syntax).
  # 
  # For example:
  # 
  # galera::repo::REPONAME::TYPE:
  #   location: 'http://repo.example.com/mysql-wsrep-<%= $vendor_version_real %>'
  # 
  $config = $_config_tmp.reduce({}) |$memo, $x| {
    # epp expects a string, so skip all other types.
    if ($x[1] =~ String) {
      $_values = inline_epp($x[1])
    } else {
      $_values = $x[1]
    }
    $memo + {$x[0] => $_values}
  }

  # Finally configure the os-specific repository.
  case $type {
    'apt': {
      apt::source { "${module_name}_${repo}":
        * => $config,
      }
    }
    'yum': {
      yumrepo { "${module_name}_${repo}":
        * => $config,
      }
    }
    default: { }
  }
}
