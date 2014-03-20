class galera::status (
  $status_password  = 'statuscheck!',
  $status_allow     = '%',
  $status_host      = 'localhost',
  $status_user      = 'clustercheck',
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
    mode => '0755',
  }

  augeas { 'mysqlchk':
    context => '/files/etc/services',
    changes => [
      "set /files/etc/services/service-name[port = '9200']/port 9200",
      "set /files/etc/services/service-name[port = '9200'] mysqlchk",
      "set /files/etc/services/service-name[port = '9200']/protocol tcp",
    ],
  }

  xinetd::service { 'mysqlchk':
    server => '/usr/local/bin/clustercheck',
    port => '9200',
    user => 'nobody',
    flags => 'REUSE',
  } 
}
