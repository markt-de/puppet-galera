node default {
  class { 'galera':
    galera_servers  => ['10.0.99.101', '10.0.99.102'],
    galera_master   => 'node1.example.com',
    vendor_type     => 'mariadb',
    root_password   => 'pa$$w0rd',
    status_password => 'pa$$w0rd',
  }
}
