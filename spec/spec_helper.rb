require 'puppetlabs_spec_helper/module_spec_helper'
require 'shared_examples'
require 'rspec-puppet-facts'
include RspecPuppetFacts


RSpec.configure do |c|
  c.alias_it_should_behave_like_to :it_configures, 'configures'
  c.alias_it_should_behave_like_to :it_raises, 'raises'
  c.default_facts = {
    puppetversion: Puppet.version,
    facterversion: Facter.version,
    lsbdistcodename: 'testing',
    ipaddress_eth1:  '10.0.0.1',
    os_maj_version: '10',
    root_home: '',
  }
end
