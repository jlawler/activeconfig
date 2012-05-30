#!/usr/bin/env ruby
require 'pp'
# TEST_CONFIG_BEGIN
# enabled: true
# TEST_CONFIG_END

# Test target dependencies

# even if a gem is installed, load cnu_config and active_config locally
dir = File.dirname __FILE__
$LOAD_PATH.unshift File.join(dir, "..", "lib")

# Configure ActiveConfig to use our test config files.
RAILS_ENV = 'development'
ENV['ACTIVE_CONFIG_PATH'] = File.expand_path(File.dirname(__FILE__) + "/active_config_test/")
ENV.delete('ACTIVE_CONFIG_OVERLAY') # Avoid gb magic.

# Test environment.
require 'rubygems'

$:.unshift File.expand_path("../../lib",__FILE__)
# Test target
require 'active_config'

# Test dependencies
require 'test/unit'
require 'fileutils' # FileUtils.touch
require 'benchmark'

AC=ActiveConfig.new
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

  def test_global
    assert_equal 101,active_config.using_array_index
  end
  def test_gbracket
    assert_equal 101,active_config[:using_array_index]
  end
  def test_rails_env
    assert_equal RAILS_ENV, active_config._suffixes.rails_env
  end

  def test_suffixes
  end

  def test_basic
    assert_equal true, active_config.test.secure_login
  end


  def test_default
    assert_equal "yo!", active_config.test.default
  end


  def test_indifferent
    assert h = active_config.test
    # STDERR.puts "h = #{h.inspect}:#{h.class}"

    assert hstr = h['hash_1']
    assert_kind_of Hash, hstr
    # STDERR.puts "hstr = #{hstr.inspect}:#{hstr.class}"

    assert hsym = h[:hash_1]
    assert hsym.object_id == hstr.object_id
  end


  def test_dot_notation
    assert h = active_config.test
    assert h = h.hash_1
    assert h.foo
  end


  def test_dot_notation_overrun
    assert_raise NoMethodError do
      active_config.test.hash_1.foo.a_bridge_too_far
    end
  end


  def test_array_notation
    assert h = active_config.test[:hash_1]
    assert a = active_config.test[:array_1]
  end


  def test_function_notation
    assert h = active_config.test(:hash_1, 'foo')
    assert_equal nil, active_config.test(:hash_1, 'foo', :too_far)
    assert_equal 'c', active_config.test(:array_1, 2)
    assert_equal nil, active_config.test(:array_1, "2")
  end


  def test_immutable
    assert active_config.test.frozen?
    assert active_config.test.hash_1.frozen?
    # ruby 1.8 and ruby 1.9 raise different exception classes
    assert_raise TypeError, RuntimeError do
      active_config.test.hash_1[:foo] = 1
    end
  end


  def test_to_yaml
    assert active_config.test.to_yaml
  end


  def test_disable_reload
    @active_config=nil
    # Clear out everything.
    active_config.reload(true)

    # Reload delay
    active_config._reload_delay = -1
    # active_config._verbose = true
    active_config._flush_cache

    # Get the name of a config file to touch.
    assert cf1 = active_config._config_files("test")
    assert cf1 = cf1[0]
      
    v = nil
    th = nil
    active_config.disable_reload do 
      # Make sure first access works inside disable reload.
      assert th = active_config.test
      assert_equal "foo", v = active_config.test.hash_1.foo

      # Get access again and insure that file was not reloaded.
      assert_equal v, active_config.test.hash_1.foo
      assert th.object_id == active_config.test.object_id
  
#       STDERR.puts "touching #{cf1.inspect}"
      FileUtils.touch(cf1)

      assert_equal v, active_config.test.hash_1.foo
      assert th.object_id == active_config.test.object_id
    end

    # STDERR.puts "reload allowed"
    #assert ! active_config._config_file_loaded
    #assert th.object_id != active_config.test.object_id
    assert_equal v, active_config.test.hash_1.foo

    #assert active_config._config_file_loaded
    assert_equal v, active_config.test.hash_1.foo
     

    # Restore reload_delay
    active_config._reload_delay = false
    active_config._verbose = false
  end


  def test_hash_merge
    assert_equal "foo", active_config.test.hash_1.foo
    assert_equal "baz", active_config.test.hash_1.bar
    assert_equal "bok", active_config.test.hash_1.bok
    assert_equal "zzz", active_config.test.hash_1.zzz
  end


  def test_array
    assert_equal [ 'a', 'b', 'c', 'd' ], active_config.test.array_1
  end


  def test_index
    assert_kind_of Hash, active_config.get_config_file(:test)
  end


  def test_config_files
    return
    #FIXME TODO:  1) Figure out if this functionality needs to be replicated
    #             2) If so, do it.
    assert_kind_of Array, cf = active_config._load_config_files("test").select{|x| x[3]}
    # STDERR.puts "cf = #{cf.inspect}"

    if ENV['ACTIVE_CONFIG_OVERLAY']
#      assert_equal 3, cf.size
    else
#      assert_equal 2, cf.size
    end

    assert_equal 4, cf[0].size
    assert_equal "test", cf[0][0]
    assert_equal "test", cf[0][1]

    assert_equal 4, cf[1].size
    if ENV['ACTIVE_CONFIG_OVERLAY'] == 'gb'
      assert_equal "test_gb", cf[1][0]
      assert_equal "test_gb", cf[1][1]

      assert_equal 4, cf[2].size
      assert_equal "test", cf[2][0]
      assert_equal "test_local", cf[2][1]
    else
      assert_equal "test", cf[1][0]
      assert_equal "test_local", cf[1][1]
    end

  end


  def test_config_changed
    return
    active_config.reload(true)

    cf1 = active_config._config_files("test")
    cf2 = active_config._config_files("test")
    cf3 = active_config._config_files("test")

    file_to_touch = cf1[1]

    # Check that _config_files is cached.
    # STDERR.puts "cf1 = #{cf1.object_id.inspect}"
    # STDERR.puts "cf2 = #{cf2.object_id.inspect}"
    assert cf1.object_id != cf2.object_id
#    assert cf1.object_id == cf3.object_id
#    FIXME TODO:  WTF Does the above 2 asserts mean???

    # STDERR.puts "cf1 = #{cf1.inspect}"
    # STDERR.puts "cf2 = #{cf2.inspect}"
    # Check that config_changed? is false, until touch.
    assert cf1.object_id != cf2.object_id
    assert_equal cf1, cf2
    #assert_equal false, active_config.config_changed?("test")

    # Touch a file.
    # $stderr.puts "file_to_touch = #{file_to_touch.inspect}"
    FileUtils.touch(file_to_touch)
    cf2 = active_config._load_config_files("test")
    # Ensure that files were not reloaded until reload(true) below.
    assert cf1.object_id != cf2.object_id
    assert ! (cf1 === cf2)
#    assert_equal true, active_config.config_changed?("test")

    # Pull config again.
    active_config.reload(true)
    cf3 = active_config._load_config_files("test")
    cf2 = active_config._load_config_files("test")
    # $stderr.puts "cf1.object_id = #{cf1.object_id}"
    # $stderr.puts "cf2.object_id = #{cf2.object_id}"
    # $stderr.puts "cf3.object_id = #{cf3.object_id}"
    # STDERR.puts "cf3 = #{cf1.inspect}"
    # STDERR.puts "cf2 = #{cf2.inspect}"

    # Insure that the list of files actually changed:
    assert cf1.object_id != cf3.object_id
    assert !(cf3 === cf1)
    assert (cf3 === cf2)
 #   assert_equal false, active_config.config_changed?("test")

    # Pull config again, expect no changes.
    cf4 = active_config._load_config_files("test")
    # STDERR.puts "cf3 = #{cf1.inspect}"
    # STDERR.puts "cf2 = #{cf2.inspect}"
    assert cf3.object_id == cf4.object_id
    assert active_config._load_config_files("test")
    assert_equal false, active_config.config_changed?("test")
 
  end


  def test_check_reload_disabled
    active_config.reload(true)

    assert_kind_of Array, active_config._config_files('test')
    
    active_config._reload_disabled = true

    assert_kind_of Array, active_config._config_files('test')

    active_config._reload_disabled = nil
  end


  def test_on_load_callback
    # STDERR.puts "test_on_load_callback"

    active_config.reload(true)
    # active_config._verbose = 1

    cf1 = active_config._config_files("test")

    assert_equal "foo", active_config.test.hash_1.foo

    sleep 1

    called_back = 0

    active_config.on_load(:test) do
      called_back += 1
      # STDERR.puts "on_load #{called_back}"
    end

    assert_equal 1, called_back

    assert_equal "foo", active_config.test.hash_1.foo
    
    
    # STDERR.puts "Not expecting config change."
    assert_nil active_config._check_config_changed
    assert_equal "foo", active_config.test.hash_1.foo
    assert_equal 1, called_back

    old_test_oid=active_config.test.object_id
    file = cf1[0]
    # STDERR.puts "Touching file #{file.inspect}"
    active_config._flush_cache 
    File.chmod(0644, file)
    FileUtils.touch(file)
    File.chmod(0444, file)

    # STDERR.puts "Expect config change."
    assert_equal "foo", active_config.test.hash_1.foo
    assert_not_equal old_test_oid, active_config.test.object_id
    assert_equal 2, called_back

    # STDERR.puts "Not expecting config change."
    assert_nil active_config._check_config_changed
    assert_equal "foo", active_config.test.hash_1.foo
    assert_equal 2, called_back

    # STDERR.puts "test_on_load_callback: END"
  end


  def test_overlay_by_name
    assert_equal nil,   active_config._suffixes.overlay

    assert_equal "foo", active_config.test.hash_1.foo
    assert_equal "foo", active_config.test_GB.hash_1.foo

    assert_equal "bok", active_config.test.hash_1.bok
    assert_equal "GB",  active_config.test_GB.hash_1.bok

    assert_equal nil,   active_config.test.hash_1.gb
    assert_equal "GB",  active_config.test_GB.hash_1.gb
  end


  def test_overlay_change
    begin
      active_config._suffixes.overlay = 'gb'
      
      assert_equal "foo", active_config.test.hash_1.foo
      assert_equal "foo", active_config.test_GB.hash_1.foo
      assert_equal "foo", active_config.test_US.hash_1.foo
      
      assert_equal "GB",  active_config.test.hash_1.bok
      assert_equal "GB",  active_config.test_GB.hash_1.bok
      assert_equal "US",  active_config.test_US.hash_1.bok
      
      assert_equal "GB",  active_config.test.hash_1.gb
      assert_equal "GB",  active_config.test_GB.hash_1.gb
      assert_equal nil,   active_config.test_US.hash_1.gb
      
      active_config._suffixes.overlay = 'us'
      
      assert_equal "foo", active_config.test.hash_1.foo
      assert_equal "foo", active_config.test_GB.hash_1.foo
      assert_equal "foo", active_config.test_US.hash_1.foo
      
      assert_equal "US", active_config.test.hash_1.bok
      assert_equal "GB", active_config.test_GB.hash_1.bok
      assert_equal "US", active_config.test_US.hash_1.bok
      
      assert_equal  nil,  active_config.test.hash_1.gb
      assert_equal "GB",  active_config.test_GB.hash_1.gb
      assert_equal  nil,  active_config.test_US.hash_1.gb
 
      active_config._suffixes.overlay = nil

    ensure
      active_config._suffixes.overlay = nil
    end
  end


  # Expand this benchmark to
  # compare with relative minimum performance, for example
  # a loop from 1 to 1000000.
  # Make this test fail if the minimum peformance criteria
  # is not met.
  # -- kurt@cashnetusa.com 2007/06/12
  def test_zzz_benchmark
    n = 10000
    bm = Benchmark.measure do 
      n.times do 
        active_config.test.hash_1.foo
      end
    end
    STDERR.puts "\n#{n}.times =>#{bm}\n"
  end

end # class

