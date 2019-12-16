# == Class galera::validate
#
# This class will ensure that the mysql cluster
# can accept connections at the point where the
# mysql::server resource is marked as complete.
#
# This is used because after returning success,
# the service is still not quite ready.
#
# We can validate connection either with
#   1) root password if given or
#   2) status password if status_check is true
# 
class galera::validate(
  String $action,
  String $catch,
  Integer $delay,
  Integer $retries,
  Optional[String] $inv_catch,
) {

  if $galera::root_password =~ String {
    $validate_host     = 'localhost'
    $validate_user     = 'root'
    $validate_password = $galera::root_password
    $validate_require  = Class['mysql::server::root_password']
  }
  elsif $galera::status_check {
    include galera::status

    $validate_host     = $galera::status_host
    $validate_user     = $galera::status_user
    $validate_password = $galera::status_password
    $validate_require  = Class['galera::status']
  }
  else {
    fail('Cannot validate connection without root_password or status_check')
  }

  if $catch {
    $truecatch = $catch
  } elsif $inv_catch {
    $truecatch = " -v ${inv_catch}"
  } else {
    fail('No catch method specified in galera validation script')
  }

  $cmd = "mysql --host=${validate_host} --user=${validate_user} --password=${validate_password} -e '${action}'"
  exec { 'validate_connection':
    path        => '/usr/bin:/bin:/usr/sbin:/sbin',
    provider    => shell,
    command     => $cmd,
    tries       => $retries,
    try_sleep   => $delay,
    subscribe   => Service['mysqld'],
    refreshonly => true,
    before      => Anchor['mysql::server::end'],
    require     => $validate_require,
  }

  Exec<| title == 'bootstrap_galera_cluster' |> ~> Exec['validate_connection']
}
