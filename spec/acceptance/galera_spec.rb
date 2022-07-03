require 'spec_helper_acceptance'

if ENV['VENDOR_TYPE'].nil? || ENV['VENDOR_TYPE'] == 'percona'

  describe 'galera' do
    describe 'default parameters' do
      let(:pp) do
        <<-MANIFEST
        # Workaround a known issue on CentOS 6, see https://tickets.puppetlabs.com/browse/MODULES-5653
        if ($facts['os']['family'] == 'RedHat') and (versioncmp($facts['os']['release']['major'], '7') < 0) {
          exec { 'create empty iptables configs':
            path    => '/usr/bin:/bin:/usr/local/bin:/usr/sbin:/sbin:/usr/local/sbin',
            command => 'touch /etc/sysconfig/iptables; touch /etc/sysconfig/ip6tables',
            before  => Class['firewall'],
          }
        }

        # When trying to workaround the docker/systemd incompatibility in
        # CentOS 7 by using an older build, the old systemd results in a new
        # issue: `systemctl daemon-reload` does not work and hence the firewall
        # service should be disabled during tests.
        if ($facts['os']['family'] == 'RedHat') and (versioncmp($facts['os']['release']['major'], '8') < 0) {
          $_configure_firewall = false
        } else {
          $_configure_firewall = true
        }

        # Setup firewall package and service, otherwise adding firewall
        # rules will fail.
        if $_configure_firewall == true {
          class { 'firewall': }
        }

        class { 'galera':
          cluster_name          => 'testcluster',
          deb_sysmaint_password => 'sysmaint',
          galera_servers        => ['127.0.0.1'],
          galera_master         => $::fqdn,
          configure_firewall    => $_configure_firewall,
          root_password         => 'root_password',
          status_password       => 'status_password',
          override_options      => {
            'mysqld' => {
              'bind_address' => '0.0.0.0',
            }
          },
          vendor_type           => 'percona',
          vendor_version        => '5.7'
        }
        MANIFEST
      end

      it 'runs successfully' do
        apply_manifest(pp, catch_failures: true)
      end

      describe port(3306) do
        it { is_expected.to be_listening.with('tcp') }
      end

      describe port(4567) do
        it { is_expected.to be_listening.with('tcp') }
      end
    end
  end

end
