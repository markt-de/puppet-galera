require 'spec_helper'

describe 'galera' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
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
          vendor_type: 'percona',
          vendor_version: '8.0',
        }
      end

      let(:garb_config_content) do
        case facts[:os]['family']
        when 'FreeBSD'
          <<~CONFIG
            # This file is managed by Puppet. DO NOT EDIT.
            garb_enable="YES"
            garb_galera_nodes="10.2.2.1"
            garb_galera_group="testcluster"
            garb_galera_options="gcs.fc_limit=256; gcs.fc_factor=0.99; gcs.fc_master_slave=YES; evs.keepalive_period=PT1S; evs.suspect_timeout=PT1M; evs.inactive_timeout=PT2M; evs.install_timeout=PT2M; evs.delayed_keep_period=PT2M; gcs.sync_donor=YES; gmcast.peer_timeout=PT10S; gmcast.time_wait=PT15S; pc.wait_prim_timeout=PT1M; pc.announce_timeout=PT10S"
          CONFIG
        else
          <<~CONFIG
            # This file is managed by Puppet. DO NOT EDIT.
            GALERA_NODES="10.2.2.1:4567"
            GALERA_GROUP="testcluster"
            GALERA_OPTIONS="gcs.fc_limit=256; gcs.fc_factor=0.99; gcs.fc_master_slave=YES; evs.keepalive_period=PT1S; evs.suspect_timeout=PT1M; evs.inactive_timeout=PT2M; evs.install_timeout=PT2M; evs.delayed_keep_period=PT2M; gcs.sync_donor=YES; gmcast.peer_timeout=PT10S; gmcast.time_wait=PT15S; pc.wait_prim_timeout=PT1M; pc.announce_timeout=PT10S"
          CONFIG
        end
      end

      context 'with arbitrator enabled' do
        let(:params) do
          default_params
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.not_to contain_class('mysql::server') }
        it { is_expected.to contain_class('galera::arbitrator') }
        it { is_expected.to contain_package('galera-arbitrator') }

        it { is_expected.to contain_service('arbitrator-service').with_enable(true) }

        describe 'with parameter: arbitrator_service_enabled=false' do
          let(:params) { default_params.deep_merge!(arbitrator_service_enabled: false) }

          it { is_expected.to contain_service('arbitrator-service').with_enable(false) }
        end

        it { is_expected.to contain_file('arbitrator-config-file').with_content(garb_config_content) }
      end
    end
  end
end
