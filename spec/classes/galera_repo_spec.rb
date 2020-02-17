require 'spec_helper'

describe 'galera' do
  let :params do
    {
      configure_repo: true,
      cluster_name: 'test',
      status_password: 'test',
    }
  end

  shared_examples_for 'repo on RedHat-family' do
    context 'for codership' do
      before(:each) do
        params.merge!(vendor_type: 'codership', vendor_version: '5.7')
      end
      it { is_expected.to contain_yumrepo('galera_codership').with(enabled: 1) }
    end

    context 'for codership with wsrep_sst_method=xtrabackup' do
      before(:each) do
        params.merge!(vendor_type: 'codership', vendor_version: '5.7', wsrep_sst_method: 'xtrabackup')
      end
      it { is_expected.to contain_yumrepo('galera_codership').with(enabled: 1) }
      it { is_expected.to contain_yumrepo('galera_percona').with(enabled: 1) }
    end

    context 'for mariadb' do
      before(:each) do
        params.merge!(vendor_type: 'mariadb', vendor_version: '10.3')
      end
      it { is_expected.to contain_yumrepo('galera_mariadb').with(enabled: 1) }
    end

    context 'for mariadb with wsrep_sst_method=xtrabackup-v2' do
      before(:each) do
        params.merge!(vendor_type: 'mariadb', vendor_version: '10.3', wsrep_sst_method: 'xtrabackup-v2')
      end
      it { is_expected.to contain_yumrepo('galera_mariadb').with(enabled: 1) }
      it { is_expected.to contain_yumrepo('galera_percona').with(enabled: 1) }
    end

    context 'for percona' do
      before(:each) do
        params.merge!(vendor_type: 'percona', vendor_version: '5.7')
      end
      it { is_expected.to contain_yumrepo('galera_percona').with(enabled: 1) }
    end

    context 'with configure_repo=false' do
      before(:each) do
        params.merge!(configure_repo: false)
      end
      it { is_expected.not_to contain_yumrepo('galera_codership') }
      it { is_expected.not_to contain_yumrepo('galera_mariadb') }
      it { is_expected.not_to contain_yumrepo('galera_percona') }
    end

    context 'with epel_needed=true (default)' do
      it { is_expected.to contain_class('epel') }
    end

    context 'with epel_needed=false' do
      before(:each) do
        params.merge!(epel_needed: false)
      end
      it { is_expected.not_to contain_class('epel') }
    end
  end

  shared_examples_for 'repo on Debian-family' do
    context 'for codership' do
      before(:each) do
        params.merge!(vendor_type: 'codership', vendor_version: '5.7')
      end
      it { is_expected.to contain_apt__source('galera_codership').with(repos: 'main') }
    end

    context 'for codership with wsrep_sst_method=xtrabackup' do
      before(:each) do
        params.merge!(vendor_type: 'codership', vendor_version: '5.7', wsrep_sst_method: 'xtrabackup')
      end
      it { is_expected.to contain_apt__source('galera_codership').with(repos: 'main') }
      it { is_expected.to contain_apt__source('galera_percona').with(repos: 'main') }
    end

    context 'for mariadb' do
      before(:each) do
        params.merge!(vendor_type: 'mariadb', vendor_version: '10.3')
      end
      it { is_expected.to contain_apt__source('galera_mariadb').with(repos: 'main') }
    end

    context 'for mariadb with wsrep_sst_method=xtrabackup-v2' do
      before(:each) do
        params.merge!(vendor_type: 'mariadb', vendor_version: '10.3', wsrep_sst_method: 'xtrabackup-v2')
      end
      it { is_expected.to contain_apt__source('galera_mariadb').with(repos: 'main') }
      it { is_expected.to contain_apt__source('galera_percona').with(repos: 'main') }
    end

    context 'for percona' do
      before(:each) do
        params.merge!(vendor_type: 'percona', vendor_version: '5.7')
      end
      it { is_expected.to contain_apt__source('galera_percona').with(repos: 'main') }
    end

    context 'with configure_repo=false' do
      before(:each) do
        params.merge!(configure_repo: false)
      end
      it { is_expected.not_to contain_apt__source('galera_codership') }
      it { is_expected.not_to contain_apt__source('galera_mariadb') }
      it { is_expected.not_to contain_apt__source('galera_percona') }
    end

    context 'with epel_needed=true should do nothing' do
      before(:each) do
        params.merge!(epel_needed: true)
      end
      it { is_expected.not_to contain_class('epel') }
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do # rubocop:disable RSpec/EmptyExampleGroup
      let(:facts) do
        facts.merge({})
      end

      case facts[:osfamily]
      when 'RedHat'
        it_configures 'repo on RedHat-family'
      when 'Debian'
        it_configures 'repo on Debian-family'
      end
    end
  end
end
