require 'spec_helper'

describe 'galera::debian' do
  let(:pre_condition) do
    "class { 'galera':
       cluster_name    => 'testcluster',
       galera_master   => 'control1',
       package_ensure  => 'present',
       status_password => 'nonempty',
       vendor_type     => 'percona',
       vendor_version  => '8.0',
    }"
  end

  shared_examples_for 'galera workarounds on Debian and Ubuntu' do
    context 'with default parameters' do
      it { is_expected.to contain_file('/etc/mysql/puppet_debfix.cnf').with_content(%r{[mysqld]}) }
      it {
        is_expected.to contain_exec('clean_up_ubuntu').with(
          command: 'service mysql stop',
          path: '/usr/bin:/bin:/usr/sbin:/sbin',
          refreshonly: true,
          subscribe: 'Package[mysql-server]',
        )
      }
      it { is_expected.to contain_file('/var/lib/mysql-install-tmp') }
      it { is_expected.to contain_exec('fix_galera_config_errors_episode_I').with(refreshonly: true) }
      it { is_expected.to contain_exec('fix_galera_config_errors_episode_II').with(refreshonly: true) }
      it { is_expected.to contain_exec('fix_galera_config_errors_episode_III').with(refreshonly: true) }
      it { is_expected.to contain_exec('fix_galera_config_errors_episode_IV').with(refreshonly: true) }
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do # rubocop:disable RSpec/EmptyExampleGroup
      let(:facts) do
        facts
      end

      case facts[:os]['family']
      when 'Debian'
        it_configures 'galera workarounds on Debian and Ubuntu'
      end
    end
  end
end
