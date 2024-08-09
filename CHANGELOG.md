# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

## [Unreleased]
This is a new major release with breaking changes. MariaDB 11.x is not yet
supported because puppetlabs/mysql lacks support for it.

### Added
* Add new parameter `$status_check_type`
* Add new parameter `$status_systemd_service_name`
* Add customization options for the xinetd service ([#177])
* Add systemd-based status check ([#191])
* Add support for new operating systems
* Add support for Percona XtraDB 8.0 and MariaDB 10.11 ([#192])

### Changed
* Remove default values: `$vendor_type`, `$vendor_version`
* Disable option `pxc-encrypt-cluster-traffic` on Percona XtraDB 8.0
* Enable systemd-based status check on RHEL 9, Debian 12 and Ubuntu 24.04 ([#191])
* Add new dependency for systemd-based status check ([#191])
* Merge internal $default_options from multiple hierarchy levels
* Update Codership APT key
* Switch unit tests to Codership/MySQL 8.0, MariaDB 10.11 and XtraDB 8.0
* Extend unit tests ([#191])

### Fixed
* Revive `binlog_format` for MariaDB ([#190])
* SST package install fails because repo is not yet configured
* Remove incompatible options from bootstrap workaround on Debian/Ubuntu
* Fix Percona XtraDB 8.0 package name on Debian/Ubuntu
* Fix Percona XtraDB 8.0 bootstrap command
* Fix Percona XtraDB `my.cnf` location on RHEL-based systems
* Percona XtraDB 8.0 no longer supports option `wsrep_sst_auth`

## [3.2.1] - 2024-03-13

### Changed
* Remove deprecated option `binlog_format` from default config

## [3.2.0] - 2024-03-13

### Changed
* Remove deprecated option `wsrep_slave_threads` from default config
* Update PDK to 3.0.1

## [3.1.0] - 2023-07-31

### Changed
* Change default value of `ensure` parameters to `present` ([#185])
* Replace deprecated function `mysql_password` ([#186])
* Update module dependencies

### Fixed
* Fix compatibility with puppetlabs/stdlib v9.0.0
* Fix GitHub Actions (unit/acceptance tests)

## [3.0.2] - 2023-07-11

### Changed
* Use modern facts in acceptance tests ([#179])

### Fixed
* Fix Puppet lint offenses ([#179])

## [3.0.1] - 2022-08-17

### Added
* Add an example Arbitrator config (see README)

### Fixed
* Fix Arbitrator service unable to read config file

### Removed
* Officially drop the concept of "stable" branches on GitHub

## [3.0.0] - 2022-07-04
This is a new major release. It supports the two most recent (long-term)
versions of Codership Galera, Percona XtraDB and MariaDB. Older versions may
still work, but they are no longer officially supported (see README).
This release contains breaking changes: Some MySQL parameters had to be removed
from the default configuration and new APT/YUM repositories were introduced.

### Added
* Add support for MariaDB 10.5 and 10.6 ([#173])
* Add support for Codership on MySQL 8.0 ([#159])
* Add support for Percona XtraDB Cluster 8.0 ([#155])

### Changed
* Add priority to Codership APT repositories (resolves installation issues)
* Use parameter for service name wherever possible ([#170])
* Switch Percona to new YUM/APT repository layout
* Switch MariaDB to new YUM/APT repository layout
* Bump module dependencies and supported Puppet versions
* Update list of supported operation systems and versions
* Migrate tests to GitHub Actions
* Add puppetlabs/yumrepo_core as new module dependency
* Update PDK to 2.5.0

### Fixed
* Fix broken /root/.my.cnf ([#166])
* Fix MariaDB/Percona/Codership repo conflict on EL8 ([#168])
* Fix creation of /root/.my.cnf when `$status_check=false` ([#171])
* Fix Arbitrator package name for Codership Galera 5.7 on EL7+EL8
* Fix Codership installation issues on Ubuntu 20.04 and EL8
* Fix most puppet-lint offenses
* Fix unit tests and acceptance tests

### Removed
* Remove query_cache_size and query_cache_type from default options ([#155])
* Remove innodb_locks_unsafe_for_binlog from default options ([#159])
* Drop official support for Debian 9, Ubuntu 18.04, CentOS 6 and FreeBSD 12.x (they may still work)
* Remove outdated examples

## [2.2.0] - 2020-08-17

### Fixed
* Fix nmap call to use IP address instead of ip:port ([#162])
* Fix path to Bash in `clustercheck` script on FreeBSD

## [2.1.0] - 2020-05-07
This is a maintenance release.

### Changed
* Fix duplicate declaration errors by replacing `ensure_resource()` with `ensure_packages()` ([#158])
* Re-enable the content-check for validating the server connection ([#152])

## [2.0.0] - 2020-04-14
This is a new major release. It aims to fix many long-standing limitations, hence it introduces several breaking changes and should be tested in non-producton environments. Starting with this release unit tests and acceptance tests are required for all new features, this should further stabilize the module.

### Added
* Add mandatory parameter `$cluster_name` (sets `wsrep_cluster_name` in server config)
* Add support for Galera Arbitrator ([#112])
* Add support for the FreeBSD operating system ([#115])
* Add support for MariaDB 10.4 ([#154])
* Add initial support for RHEL/CentOS 8 ([#154])
* Add dependency voxpupuli/epel on RHEL/CentOS systems
* Add acceptance test for Codership Galera and MariaDB

### Changed
* Officially declare all classes private, except `galera` and `galera::firewall` (see REFERENCE)
* Breaking changes in all private classes, now everything is controlled from the `galera` class
* Extensive refactoring of repository management (see README for new examples, [#119], [#112])
* Use the value of `wsrep_group_comm_port` wherever applicable in server and arbitrator config
* Use `$mysql_port` to actually configure the server port
* Automatically add WSREP provider options to server config (see README for details)
* Refactor management of `$additional_packages`
* Change merge strategy for parameters matching `*::additional_packages`
* Move parameter `$galera::repo::epel_needed` to class `galera`
* Refactor evaluation of `$galera_package_ensure` ([#145])
* Migrate to Puppet Strings ([#149])
* Convert to PDK ([#114], [#153])
* Rename private class `galera::mariadb` to `galera::redhat`
* Deprecate Puppet 5 (support will be dropped in one of the next releases)
* Spec test coverage is now at 100%
* Refine resource relationships in `galera::status` and `galera::validate`

### Fixed
* Fix bootstrap of new Percona XtraDB cluster ([#118])
* Fix bootstrap of new Codership Galera cluster
* Fix default config on CentOS/RHEL 7 for non-MariaDB installations ([#120])
* Fix package conflicts with vendor Percona ([#145])
* Fix SST method "xtrabackup" can only be used with vendor Percona ([#119])
* Fix MariaDB on CentOS/RHEL 6
* Fix APT config on Debian 8
* Fix acceptance tests and improve test coverage
* Fix Travis CI ([#153])
* Fix tests on RHEL/CentOS 6
* Fix acceptance tests on Ubuntu
* Fix usage of `$status_check` in `galera::status` ([#148])
* Make APT config compatible with recent versions of puppetlabs/apt

### Removed
* Remove `$manage_package_nmap`, functionality moved to `$manage_additional_packages`
* Remove parameters from `galera::repos`, parameters should be set in main class instead
* Remove hardcoded EPEL config (using voxpupuli/epel instead)
* Remove parameters `$grep_binary` and `$mysql_binary` (rely on properly configured paths instead)
* Remove config for unsupported Ubuntu 14.04

## [1.0.6] - 2019-10-20

### Changed
* Allow puppetlabs/stdlib 7
* Allow puppetlabs/mysql 10
* Allow puppetlabs/firewall 2
* Drop support for Ubuntu 14.04
* Add support for RHEL/CentOS 8

### Fixed
* Fix `$apt_key_server` parameter for APT repositories (#143)

## [1.0.5] - 2019-08-26

### Changed
* Change `$galera_package_ensure` default from `absent` to `present`
* Allow `mariabackup` in `$wsrep_sst_method`
* Add `MariaDB-backup` and `socat` to `$additional_packages` for MariaDB

### Fixed
* Fix RHEL MariaDB YUM repo URL (#139)
* Fix README typos and errors (#140)

## [1.0.4] - 2019-04-30
This is a maintenance release.

### Added
* Add new RPM GPG key for Percona (#131)
* Resurrect "xtrabackup-v2" SST method for Percona (#137)

### Fixed
* Fix MariaDB repo handling (#134)
* Fix scope and handling of deb_sysmaint_password (#136)

## [1.0.3] - 2019-03-03
This is a maintenance release.

### Added
* Add support for MariaDB 10.2 for Debian family (#126)
* Add support for puppetlabs-mysql 8.x, puppetlabs-stdlib 6.x

### Changed
* Drop support for Puppet 4.x

### Fixed
* Fix default galera package for MariaDB (#127)
* Fix compatibility issue with puppetlabs-mysql 8.0.0 (#128)

## [1.0.2] - 2018-11-05

### Fixed
* Fix crash on Puppet 5.5.7 (#123)
* Bump puppetlabs-mysql requirement to 6.0.0 (#125)

## [1.0.1] - 2018-11-05

### Added
* Add missing default params for MariaDB 10.1 and 10.3 on Debian (#122)

### Fixed
* Fix variables in `clustercheck.epp` (#121)
* Remove default value of `$galera_servers` to avoid migration issues (#124)
* Small style fixes

## [1.0.0] - 2018-10-09

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

## [0.7.2] - 2018-08-10
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

## [0.7.1] - 2017-06-06
* Feature: Add Percona XtraDB cluster 5.6 and 5.7 support on RedHat (experimental!)

## [0.7.0] - 2017-06-06
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

[Unreleased]: https://github.com/markt-de/puppet-galera/compare/3.2.1...HEAD
[3.2.1]: https://github.com/markt-de/puppet-galera/compare/3.2.0...3.2.1
[3.2.0]: https://github.com/markt-de/puppet-galera/compare/3.1.0...3.2.0
[3.1.0]: https://github.com/markt-de/puppet-galera/compare/3.0.2...3.1.0
[3.0.2]: https://github.com/markt-de/puppet-galera/compare/3.0.1...3.0.2
[3.0.1]: https://github.com/markt-de/puppet-galera/compare/3.0.0...3.0.1
[3.0.0]: https://github.com/markt-de/puppet-galera/compare/2.2.0...3.0.0
[2.2.0]: https://github.com/markt-de/puppet-galera/compare/2.1.0...2.2.0
[2.1.0]: https://github.com/markt-de/puppet-galera/compare/2.0.0...2.1.0
[2.0.0]: https://github.com/markt-de/puppet-galera/compare/1.0.6...2.0.0
[1.0.6]: https://github.com/markt-de/puppet-galera/compare/1.0.5...1.0.6
[1.0.5]: https://github.com/markt-de/puppet-galera/compare/1.0.4...1.0.5
[1.0.4]: https://github.com/markt-de/puppet-galera/compare/1.0.3...1.0.4
[1.0.3]: https://github.com/markt-de/puppet-galera/compare/1.0.2...1.0.3
[1.0.2]: https://github.com/markt-de/puppet-galera/compare/1.0.1...1.0.2
[1.0.1]: https://github.com/markt-de/puppet-galera/compare/1.0.0...1.0.1
[1.0.0]: https://github.com/markt-de/puppet-galera/compare/0.7.2...1.0.0
[0.7.2]: https://github.com/markt-de/puppet-galera/compare/0.7.1...0.7.2
[0.7.1]: https://github.com/markt-de/puppet-galera/compare/0.7.0...0.7.1
[0.7.0]: https://github.com/markt-de/puppet-galera/compare/0.0.6...0.7.0
[#192]: https://github.com/markt-de/puppet-galera/pull/192
[#191]: https://github.com/markt-de/puppet-galera/pull/191
[#190]: https://github.com/markt-de/puppet-galera/pull/190
[#186]: https://github.com/markt-de/puppet-galera/pull/186
[#185]: https://github.com/markt-de/puppet-galera/pull/185
[#179]: https://github.com/markt-de/puppet-galera/pull/179
[#177]: https://github.com/markt-de/puppet-galera/pull/177
[#173]: https://github.com/markt-de/puppet-galera/pull/173
[#171]: https://github.com/markt-de/puppet-galera/pull/171
[#170]: https://github.com/markt-de/puppet-galera/pull/170
[#168]: https://github.com/markt-de/puppet-galera/pull/168
[#166]: https://github.com/markt-de/puppet-galera/pull/166
[#162]: https://github.com/markt-de/puppet-galera/pull/162
[#159]: https://github.com/markt-de/puppet-galera/pull/159
[#158]: https://github.com/markt-de/puppet-galera/pull/158
[#155]: https://github.com/markt-de/puppet-galera/pull/155
[#154]: https://github.com/markt-de/puppet-galera/pull/154
[#153]: https://github.com/markt-de/puppet-galera/pull/153
[#152]: https://github.com/markt-de/puppet-galera/pull/152
[#149]: https://github.com/markt-de/puppet-galera/pull/149
[#148]: https://github.com/markt-de/puppet-galera/pull/148
[#145]: https://github.com/markt-de/puppet-galera/pull/145
[#120]: https://github.com/markt-de/puppet-galera/pull/120
[#119]: https://github.com/markt-de/puppet-galera/pull/119
[#118]: https://github.com/markt-de/puppet-galera/pull/118
[#115]: https://github.com/markt-de/puppet-galera/pull/115
[#114]: https://github.com/markt-de/puppet-galera/pull/114
[#112]: https://github.com/markt-de/puppet-galera/pull/112
