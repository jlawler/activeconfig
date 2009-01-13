require 'rubygems'
Gem::manage_gems
require 'rake/gempackagetask'

task :default => :rdoc
task :rdoc do
  sh "find  #{File.dirname(__FILE__)}/rdoc -type f| xargs -I{} git rm {}"
  sh "rm -rf #{File.dirname(__FILE__)}/rdoc" 
  sh "mv doc rdoc"
  sh "find #{File.dirname(__FILE__)}/rdoc -type f| xargs -I{} git add"
end

