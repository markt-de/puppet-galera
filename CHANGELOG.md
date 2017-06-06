# Changelog

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

