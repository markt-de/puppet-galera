# == Class: galera::firewall
#
# === Parameters
#
# [*source*]
#   (optional) The firewall source addresses to unblock
#   Defaults to undef
#
class galera::firewall (
  $source = undef,
) {
  $galera_ports = [
    $galera::mysql_port,
    $galera::wsrep_group_comm_port,
    $galera::wsrep_state_transfer_port,
    $galera::wsrep_inc_state_transfer_port]

  firewall { '4567 galera accept tcp':
    before => Anchor['mysql::server::start'],
    proto  => 'tcp',
    dport  => $galera_ports,
    action => 'accept',
    source => $source,
  }
}
