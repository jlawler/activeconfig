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
  def setup
    super
    begin
      ActiveConfig._flush_cache
      ActiveConfig._verbose = nil # default
      ActiveConfig.reload(true)
      ActiveConfig._reload_disabled = nil # default
      ActiveConfig._reload_delay = nil # default
    rescue => err
      # NOTHING
    end
  end


  def teardown
    super
  end

  def test_multi
      assert_equal  "WIN",  ActiveConfig.test.default
  end  

end
