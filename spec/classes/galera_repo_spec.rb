require 'spec_helper'

describe 'galera::repo' do
  let :params do
    {
      :repo_vendor                   => 'percona',
      :epel_needed                   => true,

      :apt_percona_repo_location     => 'http://repo.percona.com/apt/',
      :apt_percona_repo_release      => 'precise',
      :apt_percona_repo_repos        => 'main',
      :apt_percona_repo_key          => '4D1BB29D63D98E422B2113B19334A25F8507EFA5',
      :apt_percona_repo_key_server   => 'keyserver.ubuntu.com',
      :apt_percona_repo_include_src  => false,

      :apt_mariadb_repo_location     => 'http://mirror.aarnet.edu.au/pub/MariaDB/repo/5.5/ubuntu',
      :apt_mariadb_repo_release      => 'precise',
      :apt_mariadb_repo_repos        => 'main',
      :apt_mariadb_repo_key          => '199369E5404BD5FC7D2FE43BCBCB082A1BB943DB',
      :apt_mariadb_repo_key_server   => 'keyserver.ubuntu.com',
      :apt_mariadb_repo_include_src  => false,

      :apt_codership_repo_location     => 'http://releases.galeracluster.com/galera-3/ubuntu',
      :apt_codership_repo_release      => 'precise',
      :apt_codership_repo_repos        => 'main',
      :apt_codership_repo_key          => '44B7345738EBDE52594DAD80D669017EBC19DDBA',
      :apt_codership_repo_key_server   => 'keyserver.ubuntu.com',
      :apt_codership_repo_include_src  => false,

      :yum_percona_descr             => "CentOS 6 - Percona",
      :yum_percona_baseurl           => "http://repo.percona.com/centos/os/6/x86_64/",
      :yum_percona_gpgkey            => 'http://www.percona.com/downloads/percona-release/RPM-GPG-KEY-percona',
      :yum_percona_enabled           => 1,
      :yum_percona_gpgcheck          => 1,

      :yum_mariadb_descr             => 'MariaDB Yum Repo',
      :yum_mariadb_enabled           => 1,
      :yum_mariadb_gpgcheck          => 1,
      :yum_mariadb_gpgkey            => 'https://yum.mariadb.org/RPM-GPG-KEY-MariaDB',

      :yum_codership_descr             => "CentOS 6 - Codership",
      :yum_codership_baseurl           => "http://releases.galeracluster.com/centos/6/x86_64/",
      :yum_codership_gpgkey            => 'http://releases.galeracluster.com/GPG-KEY-galeracluster.com',
      :yum_codership_enabled           => 1,
      :yum_codership_gpgcheck          => 1,
    }
  end

  let :pre_condition do
    "class { 'galera':
      configure_repo => false,
      status_password => 'nonblank'
    } "
  end

  shared_examples_for 'galera::repo on RedHat' do
    context 'installing percona on redhat' do
      before { params.merge!( :repo_vendor => 'percona' ) }
      it { should contain_yumrepo('percona').with(
        :descr      => params[:yum_percona_descr],
        :enabled    => params[:yum_percona_enabled],
        :gpgcheck   => params[:yum_percona_gpgcheck],
        :gpgkey     => params[:yum_percona_gpgkey]
      ) }
    end

    context 'installing mariadb on redhat' do
      before { params.merge!( :repo_vendor => 'mariadb' ) }
      it { should contain_yumrepo('mariadb').with(
        :descr      => params[:yum_mariadb_descr],
        :enabled    => params[:yum_mariadb_enabled],
        :gpgcheck   => params[:yum_mariadb_gpgcheck],
        :gpgkey     => params[:yum_mariadb_gpgkey]
      ) }

    end
    context 'installing codership on redhat' do
      before { params.merge!( :repo_vendor => 'codership' ) }
      it { should contain_yumrepo('codership').with(
        :descr      => params[:yum_codership_descr],
        :enabled    => params[:yum_codership_enabled],
        :gpgcheck   => params[:yum_codership_gpgcheck],
        :gpgkey     => params[:yum_codership_gpgkey]
      ) }
    end
  end

  shared_examples_for 'galera::repo on Ubuntu' do
    context 'installing percona on debian' do
      before { params.merge!( :repo_vendor => 'percona' ) }
      it { should contain_apt__source('galera_percona_repo').with(
          :location => params[:apt_percona_repo_location],
          :release  => params[:apt_percona_repo_release],
          :repos    => params[:apt_percona_repo_repos],
          :key      => {
              "id"     => params[:apt_percona_repo_key],
              "server" => params[:apt_percona_repo_key_server]
          },
          :include  => {
              "src" => params[:apt_percona_repo_include_src]
          }
      ) }
    end

    context 'installing mariadb on debian' do
      before { params.merge!( :repo_vendor => 'mariadb' ) }
      it { should contain_apt__source('galera_mariadb_repo').with(
          :location => params[:apt_mariadb_repo_location],
          :release  => params[:apt_mariadb_repo_release],
          :repos    => params[:apt_mariadb_repo_repos],
          :key      => {
              "id"     => params[:apt_mariadb_repo_key],
              "server" => params[:apt_mariadb_repo_key_server]
          },
          :include  => {
              "src" => params[:apt_mariadb_repo_include_src]
          }
      ) }
    end

    context 'installing codership on debian' do
      before { params.merge!( :repo_vendor => 'codership' ) }
      it { should contain_apt__source('galera_codership_repo').with(
          :location => params[:apt_codership_repo_location],
          :release  => params[:apt_codership_repo_release],
          :repos    => params[:apt_codership_repo_repos],
          :key      => {
              "id"     => params[:apt_codership_repo_key],
              "server" => params[:apt_codership_repo_key_server]
          },
          :include  => {
              "src" => params[:apt_codership_repo_include_src]
          }
      ) }
    end
  end

  on_supported_os.each do |os,facts|
    context "on #{os}" do
      let (:facts) do
        facts.merge({})
      end

      case facts[:osfamily]
      when 'RedHat'
        it_configures 'galera::repo on RedHat'
      when 'Debian'
        if facts[:operatingsystem] == 'Ubuntu'
          it_configures 'galera::repo on Ubuntu'
        end
      end
    end
  end


end
