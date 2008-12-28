#!/usr/bin/env ruby

# TEST_CONFIG_BEGIN
# enabled: true
# TEST_CONFIG_END

# Test target dependencies

# Configure ActiveConfig to use our test config files.
RAILS_ENV = 'development'
ENV.delete('ACTIVE_CONFIG_OVERLAY') # Avoid gb magic.

# Test environment.
require 'rubygems'
# gem 'activesupport'
require 'active_support'

# Test target
require 'active_config'

# Test dependencies
require 'test/unit'
require 'fileutils' # FileUtils.touch
require 'benchmark'





class ActiveConfig::TestMulti < Test::Unit::TestCase
  def active_config
    @active_config||=ActiveConfig.new
  end
  def setup
    super
    begin
      active_config._flush_cache
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

  def test_multi
      assert_equal  "WIN",  active_config.test.default
  end  

end
