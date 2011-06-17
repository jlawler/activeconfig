#!/usr/bin/env ruby

# TEST_CONFIG_BEGIN
# enabled: true
# TEST_CONFIG_END

# Test target dependencies

# Configure ActiveConfig to use our test config files.
ENV['RAILS_ENV']='development'

ENV['ACTIVE_CONFIG_PATH'] = File.expand_path(File.dirname(__FILE__) + "/active_config_test/")

# Test environment.
require 'rubygems'

# Test target
require 'active_config'

# Test dependencies
require 'test/unit'
require 'fileutils' # FileUtils.touch
require 'benchmark'

AC=ActiveConfig.new
AC.test.secure_login
ENV['RAILS_ENV']='production'
RAILS_ENV = ENV['RAILS_ENV'] 


class ActiveConfig::Test < Test::Unit::TestCase
  def active_config
    @active_config||= ActiveConfig.new :suffixes  =>[
      nil, 
      [:overlay, nil], 
      [:local], 
      [:overlay, [:local]], 
      :config, 
      [:overlay, :config], 
      :local_config, 
      [:overlay, :local_config], 
      :hostname, 
      [:overlay, :hostname], 
      [:hostname, :config_local], 
      [:overlay, [:hostname, :config_local]]
    ] 
  end
  def setup
    super
    begin
      active_config._verbose = nil # default
      active_config.reload(true)
      active_config._reload_disabled = nil # default
      active_config._reload_delay = nil # default
    rescue => err
      # NOTHING
    end
  end


  def teardown
    super
  end


  def test_cache_clearing
    assert_equal true, AC.test.secure_login
    AC._suffixes.rails_env=proc { |sym_table|return (RAILS_ENV if defined?(RAILS_ENV))||ENV['RAILS_ENV']}
    assert_equal false, AC.test.secure_login
  end


end # class

