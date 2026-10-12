# @summary Installs and configures the Arbitrator service.
# @api private
class galera::arbitrator (
  # NOTE: These parameters are evaluated in the main galera class and
  #       MUST ONLY be set using the parameters of the main class.
  String $config_file,
  String $package_name,
  String $service_name,
) {
  ensure_packages([$package_name], { ensure => $galera::arbitrator_package_ensure })

  file { 'arbitrator-config-file':
    path    => $config_file,
    mode    => '0640',
    owner   => 'root',
    group   => 'nobody',
    content => epp($galera::arbitrator_template),
    require => [Package[$package_name]],
  }

  service { 'arbitrator-service':
    ensure    => 'running',
    name      => $service_name,
    enable    => $galera::arbitrator_service_enabled,
    subscribe => [
      Package[$package_name],
      File['arbitrator-config-file'],
    ],
  }
}
