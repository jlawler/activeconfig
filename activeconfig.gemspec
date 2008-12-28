require 'rubygems'

spec = Gem::Specification.new do |s|
s.name = 'active_config'
s.version = '0.1.'+Time.now.strftime('%Y%m%d%H%M%S')
s.author = 'Jeremy Lawler'
s.email = 'jlawler@cashnetusa.com'
s.homepage = 'http://localhost'
s.platform = Gem::Platform::RUBY
s.summary = 'An extremely flexible configuration system'
s.files = ["./test/active_config_test_multi.rb", "./test/active_config_test/test.yml", "./test/active_config_test/test_local.yml", "./test/active_config_test/test_GB.yml", "./test/active_config_test/test_US.yml", "./test/active_config_test/global.yml", "./test/cnu_config_test.rb", "./test/active_config_test_multi/patha/test.yml", "./test/active_config_test_multi/pathb/test_local.yml", "./test/active_config_test.rb", "./test/cnu_config_test/test.yml", "./test/cnu_config_test/test_local.yml", "./test/cnu_config_test/test_GB.yml", "./test/cnu_config_test/test_US.yml", "./test/cnu_config_test/global.yml", "./Rakefile", "./lib/hash_config.rb", "./lib/hash_weave.rb", "./lib/active_config.rb", "./lib/rails_database.yml", "./lib/suffixes.rb", "./lib/cnu_config.rb"]
s.require_path      = 'lib'
s.autorequire = 'active_config'
end


