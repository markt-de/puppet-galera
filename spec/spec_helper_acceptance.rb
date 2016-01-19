require 'beaker-rspec'
require 'beaker/puppet_install_helper'

run_puppet_install_helper

UNSUPPORTED_PLATFORMS = [ 'Windows', 'Solaris', 'AIX' ]

RSpec.configure do |c|
  proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))
  metadata = JSON.parse(open('metadata.json').read)
  # pull mod name from metadata.json
  modname = metadata['name'].split('-')[1]
  # pupp mod deps from metadata.json
  deps = metadata['dependencies']

  c.formatter = :documentation
  c.before :suite do
    hosts.each do |host|
      # Install the module being tested
      on host, "rm -rf /etc/puppet/modules/#{modname}"
      puppet_module_install(:source => proj_root, :module_name => modname)
      # Install module dependancies
      deps.each do |mod|
        on host, puppet('module', 'install', mod['name'])
      end

      # Print install modules
      on host, puppet('module','list'), { :acceptable_exit_codes => 0 }
    end
  end
end
