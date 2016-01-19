require 'spec_helper_acceptance'

describe 'basic galera' do
  context 'default parameters' do
    it 'should work with no errors' do
      pp= <<-EOS
class { 'galera':
  galera_servers   => ['127.0.0.1'],
  galera_master    => $::fqdn,
  root_password    => 'root_password',
  status_password  => 'status_password',
  override_options => {
    'mysqld' => {
      'bind_address' => '0.0.0.0',
    }
  }
}
      EOS

      # Run it twice and test for idempotency
      apply_manifest(pp, :catch_failures => true)
      apply_manifest(pp, :catch_changes => true)
    end

    describe port(3306) do
      it { is_expected.to be_listening.with('tcp') }
    end

    describe port(4567) do
      it { is_expected.to be_listening.with('tcp') }
    end
  end
end
