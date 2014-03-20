# == Class: galera::validate
#
# This class will ensure that the mysql cluster
# can accept connections at the point where the
# mysql::server resource is marked as complete.
# 
# This is used because after returning success,
# the service is still not quite ready.
#
# === Parameters:
#
# [*user*]
# (optional) The mysql user to use.
#  Defaults to $galera::status::status_user
#
# [*password*]
# (optional) The password for the mysql user.
#  Defaults to $galera::status::status_password
#
# [*host*]
# (optional) The mysql host to check.
#  Defaults to $galera::status::status_host
#
# [*retries*]
# (optional) Number of times to retry connection
#  Defaults to 10
#
# [*delay*]
# (optional) Seconds to sleep between attempts.
#  Defaults to 2 
#
# [*action*]
# (optional) The mysql command to run
#  Defaults to 'select user,host from mysql.user;'
#
# [*catch*]
# (optional) A string that if present indicates failure 
#  Defaults to 'ERROR' 
#
# [*inv_catch*]
# (optional) A string that if not present indicates failure  
#  Defaults to undef
#
class galera::validate(
  $user      = $galera::status::status_user,
  $password  = $galera::status::status_password,
  $host      = $galera::status::status_host,
  $retries   = 10,
  $delay     = 2,
  $action    = 'select user,host from mysql.user;',
  $catch     = 'ERROR',
  $inv_catch = 'undef'
)
{
  include galera::status

  if $catch {
    $truecatch = $catch
  } elsif $inv_catch {
    $truecatch = " -v ${inv_catch}"
  } else {
    fail('No catch method specified in galera validation script')
  }

  $cmd = "mysql --host=${host} --user=${user} --password=${password} -e '${action}'"
  exec { 'validate_connection':
    path          => '/usr/bin:/bin:/usr/sbin:/sbin',
    provider      => shell,
    command       => "ret=0; count=0; while [ \$count -lt ${retries} ]; do if ${cmd} | grep -q ${truecatch}; then ret=1; break; fi; sleep ${delay}; count=\$((\$count + 1)); done; echo \$ret | grep 0 -q;",
    subscribe     => [Exec['bootstrap_galera_cluster'], Service['mysql']],
    refreshonly   => true,
    before        => Anchor['mysql::server::end'],
    require       => Class['galera::status']
  }
}

