# @summary Open firewall ports used by galera using puppetlabs-firewall.
#
# @param source
#  Specifies the firewall source addresses to unblock. Valid options: a string. Default: `undef`
#
class galera::firewall (
  Optional[String] $source = undef,
) {
  $galera_ports = [
    $galera::mysql_port,
    $galera::wsrep_group_comm_port,
    $galera::wsrep_state_transfer_port,
    $galera::wsrep_inc_state_transfer_port,
  ]

  if (!$galera::arbitrator) {
    $_before = [Anchor['mysql::server::start']]
  } else { $_before = [] }

  firewall { '4567 galera accept tcp':
    before => $_before,
    proto  => 'tcp',
    dport  => $galera_ports,
    jump   => 'accept',
    source => $source,
  }
}
