# == Class: galera::status
#
# Configures a user and script that will check the status
# of the galera cluster,
#
# === Parameters:
#
# [*status_password*]
#  (optional) The password of the status check user
#  Defaults to 'statuscheck!'
#
# [*status_allow*]
#  (optional) The subnet to allow status checks from
#  Defaults to '%'
#
# [*status_host*]
#  (optional) The cluster to add the cluster check user to
#  Defaults to 'localhost'
#
# [*status_user*]
#  (optional) The name of the user to use for status checks
#  Defaults to 'clustercheck'
#
# [*port*]
#  (optional) Port for cluster check service
#  Defaults to 9200
#
class galera::status (
  $status_password  = 'statuscheck!',
  $status_allow     = '%',
  $status_host      = 'localhost',
  $status_user      = 'clustercheck',
  $port             = 9200
) {

  mysql_user { "${status_user}@${status_allow}":
    ensure          => 'present',
    password_hash   => mysql_password($status_password),
    require         => [File['/root/.my.cnf'],Service['mysqld']]
  } ->
  mysql_grant { "${status_user}@${status_allow}/*.*":
    ensure     => 'present',
    options    => [ 'GRANT' ],
    privileges => [ 'SELECT' ],
    table      => '*.*',
    user       => "${status_user}@${status_allow}",
    before     => Anchor['mysql::server::end']
  }

  file { '/usr/local/bin/clustercheck':
    content => template('galera/clustercheck.erb'),
    mode    => '0755',
  }

  augeas { 'mysqlchk':
    context => '/files/etc/services',
    changes => [
      "set /files/etc/services/service-name[port = '${port}']/port ${port}",
      "set /files/etc/services/service-name[port = '${port}'] mysqlchk",
      "set /files/etc/services/service-name[port = '${port}']/protocol tcp",
    ],
  }

  xinetd::service { 'mysqlchk':
    server => '/usr/local/bin/clustercheck',
    port   => $port,
    user   => 'nobody',
    flags  => 'REUSE',
  }
}
