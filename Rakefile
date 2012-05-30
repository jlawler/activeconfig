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
active_config_multi_paths=[
  File.expand_path(File.dirname(__FILE__) + "/test/active_config_test_multi/patha"),
  File.expand_path(File.dirname(__FILE__) + "/test/active_config_test_multi/pathb"),
  File.expand_path(File.dirname(__FILE__) + "/test/active_config_test_multi/pathc")]
#active_config_multi_paths=[File.expand_path(File.dirname(__FILE__) + "/test/active_config_test_multi/patha"),':',File.expand_path(File.dirname(__FILE__) + "/test/active_config_test_multi/pathb")]

task :rdoc do
  sh "rm -rf #{File.dirname(__FILE__)}/doc"
  sh "cd lib && rdoc -o ../doc " 
end
require 'rake'

task :test do 
  Dir['*/*_test.rb'].each do |f|
    puts `ruby -I lib #{f}`
  end
end

