require 'spec_helper_acceptance'

if ENV['VENDOR_TYPE'].nil? || ENV['VENDOR_TYPE'] == 'percona'

  describe 'galera' do
    describe 'default parameters' do
      let(:pp) do
        <<-MANIFEST
        # Tests will fail if `ss` is not installed.
        if ($facts['os']['family'] == 'RedHat') and (versioncmp($facts['os']['release']['major'], '8') >= 0) {
          ensure_packages('iproute')
        }

        class { 'galera':
          cluster_name          => 'testcluster',
          configure_firewall    => false,
          deb_sysmaint_password => 'sysmaint',
          galera_servers        => ['127.0.0.1'],
          galera_master         => $::fqdn,
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
