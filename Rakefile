require 'rubygems'

require 'rubygems/package_task'
begin
  require 'jeweler'
  Jeweler::Tasks.new do |s|
    s.name = 'activeconfig'
    s.author = 'Jeremy Lawler'
    s.email = 'jeremylawler@gmail.com'
    s.homepage = 'http://jlawler.github.com/activeconfig/'
    s.summary = 'An extremely flexible configuration system'
    s.description = 'An extremely flexible configuration system.
Has the ability for certain values to be "overridden" when conditions are met.
For example, you could have your production API keys only get read when the Rails.env == "production"'
    s.authors = ["Jeremy Lawler"]
  end
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install jeweler "
end

task :default => :test

task :rdoc do
  sh "rm -rf #{File.dirname(__FILE__)}/doc"
  sh "cd lib && rdoc -o ../doc " 
end

task :test do 
  Dir['*/*_test.rb'].each do |f|
    puts `ruby -I lib #{f}`
  end
end

