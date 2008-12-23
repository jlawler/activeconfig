require 'rubygems'
Gem::manage_gems
require 'rake/gempackagetask'

task :default => :test
active_config_multi_paths=[File.expand_path(File.dirname(__FILE__) + "/test/active_config_test_multi/patha"),':',File.expand_path(File.dirname(__FILE__) + "/test/active_config_test_multi/pathb")]

task :test do
  sh "ruby -I lib test/active_config_test.rb"
  puts "\n\n"
  exception1,exception2=nil,nil
  begin 
    ENV['ACTIVE_CONFIG_PATH'] =  active_config_multi_paths.join('') 
    sh "ruby -I lib test/active_config_test_multi.rb"
  rescue Object => exception1
  end
  puts "\n\n"
  begin 
    ENV['ACTIVE_CONFIG_PATH'] =  active_config_multi_paths.reverse.join('') 
    sh "ruby -I lib test/active_config_test_multi.rb"
    rescue Object => exception2
  end
  raise exception1 if exception1
  raise exception2 if exception2
end
spec = Gem::Specification.new do |s|
s.name = 'active_config'
s.version = '0.1.'+Time.now.strftime('%Y%m%d%H%M%S')
s.author = 'Jeremy Lawler'
s.email = 'jlawler@cashnetusa.com'
s.homepage = 'http://localhost'
s.platform = Gem::Platform::RUBY
s.summary = 'An extremely flexible configuration system'
s.files = FileList["{bin,docs,lib,test}/**/*"].exclude('rdoc').to_a
s.require_path      = 'lib'
s.autorequire = 'active_config'
end

Rake::GemPackageTask.new(spec) do |pkg|
    pkg.need_tar = true
end

