# Changelog

## 1.0.3
This is a maintenance release.

### Added
* Add support for MariaDB 10.2 for Debian family (#126)
* Add support for puppetlabs-mysql 8.x, puppetlabs-stdlib 6.x

### Changed
* Drop support for Puppet 4.x

### Fixed
* Fix default galera package for MariaDB (#127)
* Fix compatibility issue with puppetlabs-mysql 8.0.0 (#128)

## 1.0.2

### Fixed
* Fix crash on Puppet 5.5.7 (#123)
* Bump puppetlabs-mysql requirement to 6.0.0 (#125)

## 1.0.1

### Added
* Add missing default params for MariaDB 10.1 and 10.3 on Debian (#122)

### Fixed
* Fix variables in `clustercheck.epp` (#121)
* Remove default value of `$galera_servers` to avoid migration issues (#124)
* Small style fixes

## 1.0.0

### Summary
This is the first release after extensive code refactoring and introduces multiple incompatible changes. It also drops support for EOL Puppet releases. Please try first in a test environment to avoid serious breakage. The 0.7 release series is considered obsolete now.

### Added
* Add Hiera 5 module data, this will make it easy to add support for new versions/vendors
* Add support for current versions of Percona XtraDB, Codership Galera Cluster and MariaDB
* Add documentation for all parameters (README)

### Changed
* Drop params.pp, move defaults to hiera module data (and provide a compatibility layer for non-hiera envs)
* Change default values of `$vendor_version` (use most recent version, depending on OS)
* Rename all `$galera::repo` parameters
* Change names of APT/YUM repos (it's recommended to purge unmanaged repositories, otherwise old repos must be removed manually)
* Change `$sst_method`: Drop support for `xtrabackup-v2` option, `xtrabackup` must be used instead
* Change `$bind_address`: Default to `::`
* Change `$galera_servers` and `$local_ip`: Default to `$facts['networking']['ip']`
* Change `$root_password` and `$status_password`: Drop insecure default values, instead the user is expected to provide values
* Change default value of `$galera_package_ensure` to `absent` to avoid package conflicts in Percona 5.7

### Removed
- Drop support for EOL operating systems: CentOS 5, Debian 7, Ubuntu 12.04
- Drop support for EOL databases: MariaDB 5.5 (except on Ubuntu 14.04)
- Drop support for Puppet 3 and other EOL releases, require Puppet 4.10+

### Fixed
* Fix bootstrap_command in multiple scenarios
* Fix package names and service names
* Style fixes

## 0.7.2
* Enhancement: Use dport parameter for puppetlabs-firewall (#59)
* Enhancement: Remove upper restriction on puppetlabs-apt (#98)
* Enhancement: Add galera_package_parameter, so we can ensure version on galera package (#100)
* Enhancement: Make bootstrap_command configurable (#101)
* Enhancement: Add possibility to purge config dir (#101)
* Enhancement: Update upper restriction on puppetlabs-mysql
* Bugfix: Use an unlisted service type instead to avoid augeas dependency (#101)
* Bugfix: Support systemd bootstrap in Ubuntu and Debian (#105)
* Bugfix: Fix mysql dependency cycle (#107)
* License: Relicense under 2-Clause BSD license (#92)

## 0.7.1
* Feature: Add Percona XtraDB cluster 5.6 and 5.7 support on RedHat (experimental!)

## 0.7.0
* WARNING: First release in almost a year, please use with caution!
* Feature: Support MySQL 5.6 and 5.7 with codership repo (#76, #86)
* Feature: Allow Tinkering with mysqlchk Logging (#79)
* Feature: Add Percona xtradb cluster 5.7 support (#85)
* Feature: Updates for MariaDB version with systemd support (#90)
* Feature: Add new parameter $create_status_user (#88)
* Feature: Allow to disable installation of additional packages (#77)
* Feature: Allow custom values for parameter $mysql_service_name (#87)
* Bugfix: Update for debian-sys-maint (#78)
* Bugfix: Update Percona key and server (#81)
* Bugfix: Fix debian-sys-maint password for Puppet 4 (#83)
* Bugfix: Drop use of host discovery in nmap probe (#84)
* Bugfix: Fix mysqlchk entry in /etc/services on CentOS (#89)
* Bugfix: Correct typo in package name (#91)

## 0.6.0
* Bump puppet-mysql requirement to 3.8.0
* Recent dependency cycle fixes require the latest mysql module

## 0.5.0
* Update README

## 0.4.0
* Bugfix: Fixes for problems when running on RedHat

## 0.3.0
* Feature: Expose create_root_user flag

## 0.2.0
* Bugfix: Fix service title for debian

## 0.1.0
* Bugfix: Additional package as an ensure_resource

