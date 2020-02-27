# frozen_string_literal: true

def pre_run
  apply_manifest("class { 'galera': cluster_name => 'testcluster' }", catch_failures: true)
end

RSpec.configure do |c|
  c.before :suite do
    if os[:family] == 'debian' || os[:family] == 'ubuntu'
      # needed for the puppet fact
      apply_manifest("package { 'lsb-release': ensure => installed, }", expect_failures: false)
    end
    # needed for the grant tests, not installed on el7 docker images
    apply_manifest("package { 'which': ensure => installed, }", expect_failures: false)
  end
end
