node default {
  class { 'galera':
    galera_servers  => ['192.168.99.101','192.168.99.102'],
    galera_master   => 'control1.domain.name',
    vendor_type     => 'mariadb',
    status_password => 'mariadb',
    bind_address    => $::ipaddress_enp0s8,
  }
}
