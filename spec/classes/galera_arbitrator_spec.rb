require 'spec_helper'

describe 'galera' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts.merge({})
      end

      let(:default_params) do
        {
          arbitrator: true,
          arbitrator_config_file: '/etc/default/garb',
          arbitrator_package_name: 'galera-arbitrator',
          arbitrator_service_name: 'garb',
          cluster_name: 'testcluster',
          galera_servers: ['10.2.2.1'],
          galera_master: 'control1',
          root_password: 'test',
          deb_sysmaint_password: 'test',
          status_password: 'test',
        }
      end

      context 'with arbitrator enabled' do
        let(:params) do
          default_params
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.not_to contain_class('mysql::server') }
        it { is_expected.to contain_package('galera-arbitrator') }

        it { is_expected.to contain_service('arbitrator-service').with_enable(true) }

        describe 'with parameter: arbitrator_service_enabled=false' do
          let(:params) { { arbitrator_service_enabled: false } }

          it { is_expected.to contain_service('arbitrator-service').with_enable(false) }
        end

        it { is_expected.to contain_file('arbitrator-config-file').with_content(%r{GALERA_GROUP="testcluster"}) }
        it { is_expected.to contain_file('arbitrator-config-file').with_content(%r{GALERA_NODES="10.2.2.1:4567"}) }
      end
    end
  end
end
