
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

