source ENV['GEM_SOURCE'] || 'https://rubygems.org'

group :development, :test do
  gem 'puppetlabs_spec_helper',  :require => false
  gem 'puppet-lint',             :require => false
  gem 'rspec-puppet-facts',      :require => false
  gem 'rake',                    :require => false
  gem 'rspec',                   :require => false
  gem 'rspec-puppet',            :require => false
  gem 'json',                    :require => false
end

if puppetversion = ENV['PUPPET_GEM_VERSION']
  gem 'puppet', puppetversion, :require => false
else
  gem 'puppet', :require => false
end

group :system_tests do
  gem 'beaker-rspec',                 :require => 'false'
  gem 'beaker-puppet_install_helper', :require => 'false'
end

# vim:ft=ruby
