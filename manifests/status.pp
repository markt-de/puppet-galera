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
# [*available_when_donor*]
#  (optional) When set to 1, the node will remain in the cluster
#  when it enters donor mode. A value of 0 will remove the node
#  from the cluster.
#  Defaults to 0
#
# [*available_when_readonly*]
#  (optional) When set to 0, clustercheck will return a 503
#  Service Unavailable if the node is in the read_only state,
#  as defined by the "read_only" mysql variable. Values other
#  than 0 have no effect.
#  Defaults to -1
#
class galera::status (
  $status_password  = 'statuscheck!',
  $status_allow     = 'localhost',
  $status_host      = 'localhost',
  $status_user      = 'clustercheck',
  $port             = 9200,
  $available_when_donor    = 0,
  $available_when_readonly = -1,
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
    before  => Anchor['mysql::server::end'],
  }

  xinetd::service { 'mysqlchk':
    server                  => '/usr/local/bin/clustercheck',
    port                    => $port,
    service_type            => 'UNLISTED',
    user                    => 'nobody',
    flags                   => 'REUSE',
    log_on_success          => '',
    log_on_success_operator => '=',
    before                  => Anchor['mysql::server::end'],
  }
}
