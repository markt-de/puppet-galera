# == Class galera::validate
#
# This class will ensure that the mysql cluster
# can accept connections at the point where the
# mysql::server resource is marked as complete.
#
# This is used because after returning success,
# the service is still not quite ready.
#
class galera::validate(
  String $action,
  String $catch,
  Integer $delay,
  String $host = $galera::status_host,
  String $password = $galera::status_password,
  Integer $retries,
  String $user = $galera::status_user,
  Optional[String] $inv_catch,
) {
  include galera::status

  if $catch {
    $truecatch = "-v ${catch}"
  } elsif $inv_catch {
    $truecatch = "${inv_catch}"
  } else {
    fail('No catch method specified in galera validation script')
  }

  $cmd = "mysql --host=${host} --user=${user} --password=${password} -e '${action}' | grep -q ${truecatch}"
  exec { 'validate_connection':
    path        => '/usr/bin:/bin:/usr/sbin:/sbin',
    provider    => shell,
    command     => $cmd,
    tries       => $retries,
    try_sleep   => $delay,
    subscribe   => Service['mysqld'],
    refreshonly => true,
    before      => Anchor['mysql::server::end'],
    require     => Class['galera::status']
  }

  Exec<| title == 'bootstrap_galera_cluster' |> ~> Exec['validate_connection']
}
