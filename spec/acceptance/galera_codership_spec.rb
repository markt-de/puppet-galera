require 'spec_helper_acceptance'

if ENV['VENDOR_TYPE'] == 'codership'

  describe 'galera' do
    describe 'with vendor codership enabled' do
      let(:pp) do
        <<-MANIFEST
        # Codership's MySQL service fails to start if apparmor is not installed.
        if ($facts['os']['name'] == 'Ubuntu') {
          stdlib::ensure_packages('apparmor-utils')
        }

        # Tests will fail if `ss` is not installed.
        if ($facts['os']['family'] == 'RedHat') and (versioncmp($facts['os']['release']['major'], '8') >= 0) {
          stdlib::ensure_packages('iproute')
        }

        class { 'galera':
          cluster_name          => 'testcluster',
          deb_sysmaint_password => 'sysmaint',
          configure_firewall    => false,
          galera_servers        => ['127.0.0.1'],
          galera_master         => $facts['networking']['fqdn'],
          root_password         => 'root_password',
          status_password       => 'status_password',
          override_options      => {
            'mysqld' => {
              'bind_address' => '0.0.0.0',
            }
          },
          vendor_type           => 'codership',
          vendor_version        => '8.0'
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
