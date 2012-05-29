require 'rubygems'

require 'rake/gempackagetask'
begin
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.name = 'activeconfig'
    s.author = 'Jeremy Lawler'
    s.email = 'jlawler@cashnetusa.com'
    s.homepage = 'http://jlawler.github.com/activeconfig/'
    s.summary = 'An extremely flexible configuration system'
    s.authors = ["Jeremy Lawler"]
  end
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install jeweler "
end

task :default => :test
active_config_multi_paths=[File.expand_path(File.dirname(__FILE__) + "/test/active_config_test_multi/patha"),':',File.expand_path(File.dirname(__FILE__) + "/test/active_config_test_multi/pathb")]

task :rdoc do
  sh "rm -rf #{File.dirname(__FILE__)}/doc"
  sh "cd lib && rdoc -o ../doc " 
end
task :test do
  sh "ruby -I lib test/active_config_test.rb"
  puts "\n\n"
  exception1,exception2,exception3=nil,nil,nil
  begin 
    ENV['ACTIVE_CONFIG_PATH'] =  active_config_multi_paths.join('') 
    sh "ruby -I lib test/active_config_test_multi.rb"
  rescue Object => exception1
  end
  puts "\n\n"
  begin 
    ENV['ACTIVE_CONFIG_PATH'] =  active_config_multi_paths.reverse.join('') 
    sh "ruby -I lib test/active_config_test_multi.rb"
    sh "ruby -I lib test/env_test.rb"
    rescue Object => exception2
  end
  x=exception1 ||exception2 
  raise x if x
end
task :cnu_config_test do 
  sh "ruby -I lib test/cnu_config_test.rb"
  puts "\n\n"
  begin
    ENV['CNU_CONFIG_PATH'] =  cnu_config_multi_paths.join('')
    sh "ruby -I lib test/cnu_config_test.rb"
  rescue Object => exception3
  end
end


