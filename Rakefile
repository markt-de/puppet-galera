require 'rake'
require 'puppetlabs_spec_helper/rake_tasks'

require 'puppet-lint/tasks/puppet-lint'
PuppetLint.configuration.fail_on_warnings = true
PuppetLint.configuration.send('disable_names_containing_dash')
PuppetLint.configuration.send('disable_80chars')
PuppetLint.configuration.send('disable_class_parameter_defaults')
PuppetLint.configuration.ignore_paths = ["vendor/**/*.pp", "spec/**/*.pp"]

require 'puppet/face'
desc "Validate manifests"
task :validate do
  Puppet::Face[:parser, '0.0.1'].validate(FileList['**/*.pp'].exclude('vendor/**/*.pp', 'spec/**/*.pp').join())
end

task :default => [:spec, :lint]
