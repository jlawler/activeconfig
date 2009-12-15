#!/usr/bin/env ruby

=begin rdoc

# Prints info from  to STDOUT.
#
# Example:
#
#  > active_config httpd.httpd.domain.portal.primary httpd.httpd.domain.frontend.primary
# portal.cashnetusa.com
# www.cashnetusa.com
#
#  > ACTIVE_CONFIG_OVERLAY=gb active_config httpd.httpd.domain.portal.primary httpd.httpd.domain.frontend.primary
# portaluk.cashnetusa.com
# www.quickquid.co.uk
#
#  > ACTIVE_CONFIG_OVERLAY=gb RAILS_ENV=production active_config --PRODDB 'database[RAILS_ENV].database'
# PRODDB=activeapp_dev_uk
#  > ACTIVE_CONFIG_OVERLAY=us RAILS_ENV=production active_config --PRODDB 'database[RAILS_ENV].database'
# PRODDB=activeapp_dev

=end

$:.unshift File.expand_path(File.dirname(__FILE__) + '/lib/ruby')

# Need to remove active_config's dependency on activesupport.
require 'rubygems'
gem 'activesupport'

# Yuck!
RAILS_ENV = ENV['RAILS_ENV'] || 'development'

require 'active_config'

name = ''

ARGV.each do | x |
  if x =~ /^--(.+)/
    name = "#{$1}="
  else 
    puts(name + (eval(".#{x}").to_s))
  end
end

exit 0

