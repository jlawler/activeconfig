spec = Gem::Specification.new do |s|
version='0.1.3'
if ENV['dev'] or  ENV['RAILS_ENV']=='development'
  version <<  Time.now.strftime('.%Y%m%d%H%M%S')
end

s.name = 'activeconfig'
s.version = version
s.author = 'Jeremy Lawler'
s.email = 'jlawler@cashnetusa.com'
s.homepage = 'http://jlawler.github.com/activeconfig/'
s.platform = Gem::Platform::RUBY
s.summary = 'An extremely flexible configuration system'
s.files = ["./lib/active_config/suffixes.rb", "./lib/active_config/hash_config.rb", "./lib/active_config/hash_weave.rb", "./lib/active_config.rb", "./bin/active_config.rb", "./test/active_config_test_multi.rb", "./test/active_config_test.rb", "./test/cnu_config_test/global.yml", "./test/cnu_config_test/test.yml", "./test/cnu_config_test/test_local.yml", "./test/cnu_config_test/test_GB.yml", "./test/cnu_config_test/test_US.yml", "./test/active_config_test_multi/pathb/test_local.yml", "./test/active_config_test_multi/patha/test.yml", "./test/active_config_test/test_config.yml", "./test/active_config_test/global.yml", "./test/active_config_test/test.yml", "./test/active_config_test/test_local.yml", "./test/active_config_test/test_GB.yml", "./test/active_config_test/test_US.yml", "./test/cnu_config_test.rb"]

s.require_path      = 'lib'
s.autorequire = 'active_config'
end


