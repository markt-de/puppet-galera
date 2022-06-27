# @summary Validate that the cluster can accept connections at the point where
#   the `mysql::server` resource is marked as complete.
#   This is used because after returning success, the service is still not quite ready.
#
# @api private
#
# @param action
#  Specifies the MySQL/MariaDB command to run. Valid options: a string. Default: `select count(1);`
# @param catch
#  Specifies a string that if present indicates failure. Valid options: a string. Default: `ERROR`
# @param delay
#  Specifies the seconds to sleep between attempts. Valid options: an integer: Default: `3`
# @param inv_catch
#  Specifies a string that if not present indicates failure. Valid options: a string. Default: `undef`
# @param retries
#  Specifies the number of times to retry connection. Valid options: an integer. Default: `20`
#
class galera::validate(
  String $action,
  String $catch,
  Integer $delay,
  Integer $retries,
  Optional[String] $inv_catch,
) {

  if $galera::status_check {
    $validate_host     = $galera::status_host
    $validate_user     = $galera::status_user
    $validate_password = $galera::status_password
  } elsif $galera::root_password =~ String {
    $validate_host     = 'localhost'
    $validate_user     = 'root'
    $validate_password = $galera::root_password
  }
  else {
    fail('Cannot validate connection without $root_password or $status_check')
  }

  if $catch {
    $truecatch = " -v ${catch}"
  } elsif $inv_catch {
    $truecatch = $inv_catch
  } else {
    fail('No catch method specified in galera validation script')
  }

  $cmd = "mysql --host=${validate_host} --user=${validate_user} --password=${validate_password} -e '${action}' | grep -q ${truecatch}"
  exec { 'validate_connection':
    path        => '/usr/bin:/bin:/usr/local/bin:/usr/sbin:/sbin:/usr/local/sbin',
    provider    => shell,
    command     => $cmd,
    tries       => $retries,
    try_sleep   => $delay,
    subscribe   => Service[$galera::mysql_service_name],
    refreshonly => true,
  }

  # Ensure that the cluster was bootstrapped, then notify to trigger a validation.
  Exec<| title == 'bootstrap_galera_cluster' |> ~> Exec['validate_connection']
}
