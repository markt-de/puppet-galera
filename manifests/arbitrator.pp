# @summary Installs and configures the Arbitrator service.
# @api private
class galera::arbitrator(
  # NOTE: These parameters are evaluated in the main galera class and
  #       MUST ONLY be set using the parameters of the main class.
  String $config_file,
  String $package_name,
  String $service_name,
) {
  ensure_resource(package, [$package_name],
  {
    ensure => $galera::arbitrator_package_ensure,
  })

  file { $config_file:
    ensure  => 'present',
    mode    => '0600',
    content => epp($galera::arbitrator_template),
    require => [Package[$package_name]],
  }

  service { $service_name:
    enable    => $galera::arbitrator_service_enabled,
    subscribe => [
        Package[$package_name],
        File[$config_file]
      ]
  }
}
