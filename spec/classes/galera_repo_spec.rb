require 'spec_helper'

describe 'galera' do
  let(:params) do
    {
      configure_repo: true,
      cluster_name: 'testcluster',
      status_password: 'test',
    }
  end

  # XXX Temporary workaround for Ubuntu 24.04
  let(:percona_repo_channel_var1) do
    if facts.dig(:os, 'name') == 'Ubuntu' && facts.dig(:os, 'release', 'full') == '24.04'
      'testing'
    else
      'main'
    end
  end

  # XXX Temporary workaround for Ubuntu 24.04
  let(:percona_repo_channel_var2) do
    if facts.dig(:os, 'name') == 'Ubuntu' && facts.dig(:os, 'release', 'full') == '24.04'
      'experimental'
    else
      'main'
    end
  end

  shared_examples_for 'repo on RedHat-family' do
    context 'for codership' do
      before(:each) do
        params.deep_merge!(vendor_type: 'codership', vendor_version: '8.0')
      end
      it { is_expected.to contain_galera__repo__config('codership') }
      it { is_expected.to contain_galera__repo__config('codership_lib') }
      it { is_expected.to contain_yumrepo('galera_codership').with(enabled: 1) }
      it { is_expected.to contain_yumrepo('galera_codership_lib').with(enabled: 1) }
    end

    context 'for codership with wsrep_sst_method=xtrabackup' do
      before(:each) do
        params.deep_merge!(vendor_type: 'codership', vendor_version: '8.0', wsrep_sst_method: 'xtrabackup')
      end
      it { is_expected.to contain_galera__repo__config('codership') }
      it { is_expected.to contain_galera__repo__config('codership_lib') }
      it { is_expected.to contain_galera__repo__config('percona_tools') }
      it { is_expected.to contain_yumrepo('galera_codership').with(enabled: 1) }
      it { is_expected.to contain_yumrepo('galera_codership_lib').with(enabled: 1) }
      it { is_expected.to contain_yumrepo('galera_percona_tools').with(enabled: 1) }
    end

    context 'for mariadb' do
      before(:each) do
        params.deep_merge!(vendor_type: 'mariadb', vendor_version: '10.11')
      end
      it { is_expected.to contain_galera__repo__config('mariadb') }
      it { is_expected.to contain_yumrepo('galera_mariadb').with(enabled: 1) }
    end

    context 'for mariadb with wsrep_sst_method=xtrabackup-v2' do
      before(:each) do
        params.deep_merge!(vendor_type: 'mariadb', vendor_version: '10.11', wsrep_sst_method: 'xtrabackup-v2')
      end
      it { is_expected.to contain_galera__repo__config('mariadb') }
      it { is_expected.to contain_galera__repo__config('percona_tools') }
      it { is_expected.to contain_yumrepo('galera_mariadb').with(enabled: 1) }
      it { is_expected.to contain_yumrepo('galera_percona_tools').with(enabled: 1) }
    end

    context 'for percona' do
      before(:each) do
        params.deep_merge!(vendor_type: 'percona', vendor_version: '8.0')
      end
      it { is_expected.to contain_galera__repo__config('percona') }
      it { is_expected.to contain_galera__repo__config('percona_tools') }
      it { is_expected.to contain_yumrepo('galera_percona').with(enabled: 1) }
      it { is_expected.to contain_yumrepo('galera_percona_tools').with(enabled: 1) }
    end

    context 'with configure_repo=false' do
      before(:each) do
        params.deep_merge!(vendor_type: 'codership', vendor_version: '8.0', configure_repo: false)
      end
      it { is_expected.not_to contain_galera__repo__config('codership') }
      it { is_expected.not_to contain_galera__repo__config('codership_lib') }
      it { is_expected.not_to contain_galera__repo__config('mariadb') }
      it { is_expected.not_to contain_galera__repo__config('percona') }
      it { is_expected.not_to contain_galera__repo__config('percona_tools') }
      it { is_expected.not_to contain_yumrepo('galera_codership') }
      it { is_expected.not_to contain_yumrepo('galera_codership_lib') }
      it { is_expected.not_to contain_yumrepo('galera_mariadb') }
      it { is_expected.not_to contain_yumrepo('galera_percona') }
      it { is_expected.not_to contain_yumrepo('galera_percona_tools') }
    end

    context 'with epel_needed=true (default)' do
      before(:each) do
        params.deep_merge!(vendor_type: 'codership', vendor_version: '8.0')
      end
      it { is_expected.to contain_class('epel') }
    end

    context 'with epel_needed=false' do
      before(:each) do
        params.deep_merge!(vendor_type: 'codership', vendor_version: '8.0', epel_needed: false)
      end
      it { is_expected.not_to contain_class('epel') }
    end
  end

  shared_examples_for 'repo on Debian-family' do
    context 'for codership' do
      before(:each) do
        params.deep_merge!(vendor_type: 'codership', vendor_version: '8.0')
      end
      it { is_expected.to contain_galera__repo__config('codership') }
      it { is_expected.to contain_galera__repo__config('codership_lib') }
      it { is_expected.to contain_apt__source('galera_codership').with(repos: 'main') }
      it { is_expected.to contain_apt__source('galera_codership_lib').with(repos: 'main') }
    end

    context 'for codership with wsrep_sst_method=xtrabackup' do
      before(:each) do
        params.deep_merge!(vendor_type: 'codership', vendor_version: '8.0', wsrep_sst_method: 'xtrabackup')
      end
      it { is_expected.to contain_galera__repo__config('codership') }
      it { is_expected.to contain_galera__repo__config('codership_lib') }
      it { is_expected.to contain_galera__repo__config('percona_tools') }
      it { is_expected.to contain_apt__source('galera_codership').with(repos: 'main') }
      it { is_expected.to contain_apt__source('galera_codership_lib').with(repos: 'main') }
      it { is_expected.to contain_apt__source('galera_percona_tools').with(repos: percona_repo_channel_var1) }
    end

    context 'for mariadb' do
      before(:each) do
        params.deep_merge!(vendor_type: 'mariadb', vendor_version: '10.11')
      end
      it { is_expected.to contain_apt__source('galera_mariadb').with(repos: 'main') }
    end

    context 'for mariadb with wsrep_sst_method=xtrabackup-v2' do
      before(:each) do
        params.deep_merge!(vendor_type: 'mariadb', vendor_version: '10.11', wsrep_sst_method: 'xtrabackup-v2')
      end
      it { is_expected.to contain_galera__repo__config('mariadb') }
      it { is_expected.to contain_galera__repo__config('percona_tools') }
      it { is_expected.to contain_apt__source('galera_mariadb').with(repos: 'main') }
      it { is_expected.to contain_apt__source('galera_percona_tools').with(repos: percona_repo_channel_var1) }
    end

    context 'for percona' do
      before(:each) do
        params.deep_merge!(vendor_type: 'percona', vendor_version: '8.0')
      end
      it { is_expected.to contain_galera__repo__config('percona') }
      it { is_expected.to contain_galera__repo__config('percona_tools') }
      it { is_expected.to contain_apt__source('galera_percona').with(repos: percona_repo_channel_var2) }
      it { is_expected.to contain_apt__source('galera_percona_tools').with(repos: percona_repo_channel_var1) }
    end

    context 'with configure_repo=false' do
      before(:each) do
        params.deep_merge!(vendor_type: 'codership', vendor_version: '8.0', configure_repo: false)
      end
      it { is_expected.not_to contain_galera__repo__config('codership') }
      it { is_expected.not_to contain_galera__repo__config('codership_lib') }
      it { is_expected.not_to contain_galera__repo__config('mariadb') }
      it { is_expected.not_to contain_galera__repo__config('percona') }
      it { is_expected.not_to contain_galera__repo__config('percona_tools') }
      it { is_expected.not_to contain_apt__source('galera_codership') }
      it { is_expected.not_to contain_apt__source('galera_codership_lib') }
      it { is_expected.not_to contain_apt__source('galera_mariadb') }
      it { is_expected.not_to contain_apt__source('galera_percona') }
      it { is_expected.not_to contain_apt__source('galera_percona_tools') }
    end

    context 'with epel_needed=true should do nothing' do
      before(:each) do
        params.deep_merge!(vendor_type: 'codership', vendor_version: '8.0', epel_needed: true)
      end
      it { is_expected.not_to contain_class('epel') }
    end
  end

  on_supported_os.each do |os, facts|
    context "on #{os}" do # rubocop:disable RSpec/EmptyExampleGroup
      let(:facts) do
        facts
      end

      case facts[:os]['family']
      when 'RedHat'
        it_configures 'repo on RedHat-family'
      when 'Debian'
        it_configures 'repo on Debian-family'
      end
    end
  end
end
