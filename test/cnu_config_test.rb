#!/usr/bin/env ruby

# TEST_CONFIG_BEGIN
# enabled: true
# TEST_CONFIG_END

# Test target dependencies

# even if a gem is installed, load cnu_config and active_config locally
dir = File.dirname __FILE__
$LOAD_PATH.unshift File.join(dir, "..", "lib")

# Configure CnuConfig to use our test config files.
RAILS_ENV = 'development'
ENV['CNU_CONFIG_PATH'] = File.expand_path(File.dirname(__FILE__) + "/cnu_config_test/")
ENV.delete('CNU_CONFIG_OVERLAY') # Avoid gb magic.

# Test environment.
require 'rubygems'

# Test dependencies
require 'test/unit'
require 'fileutils' # FileUtils.touch
require 'benchmark'

# Test target
require 'cnu_config'


class CnuConfigClass::Test < Test::Unit::TestCase
  def setup
    super
    begin
      CnuConfig._verbose = nil # default
      CnuConfig.reload(true)
      CnuConfig._reload_disabled = nil # default
      CnuConfig._reload_delay = nil # default
    rescue => err
      # NOTHING
    end
  end


  def teardown
    super
  end


  def test_mode
    assert_equal RAILS_ENV, CnuConfig._mode
  end

  def test_suffixes
  end

  def test_basic
    assert_equal true, CnuConfig.test.secure_login
  end


  def test_default
    assert_equal "yo!", CnuConfig.test.default
  end


  def test_indifferent
    assert h = CnuConfig.test
    # STDERR.puts "h = #{h.inspect}:#{h.class}"

    assert hstr = h['hash_1']
    assert_kind_of Hash, hstr
    # STDERR.puts "hstr = #{hstr.inspect}:#{hstr.class}"

    assert hsym = h[:hash_1]
    assert hsym.object_id == hstr.object_id
  end


  def test_dot_notation
    assert h = CnuConfig.test
    assert h = h.hash_1
    assert h.foo
  end


  def test_dot_notation_overrun
    assert_raise NoMethodError do
      CnuConfig.test.hash_1.foo.a_bridge_too_far
    end
  end


  def test_array_notation
    assert h = CnuConfig.test[:hash_1]
    assert a = CnuConfig.test[:array_1]
  end


  def test_function_notation
    assert h = CnuConfig.test(:hash_1, 'foo')
    assert_equal nil, CnuConfig.test(:hash_1, 'foo', :too_far)
    assert_equal 'c', CnuConfig.test(:array_1, 2)
    assert_equal nil, CnuConfig.test(:array_1, "2")
  end


  def test_immutable
    assert CnuConfig.test.frozen?
    assert CnuConfig.test.hash_1.frozen?
    assert_raise TypeError do
      CnuConfig.test.hash_1[:foo] = 1
    end
  end


  def test_to_yaml
    assert CnuConfig.test.to_yaml
  end


  def test_disable_reload
    # Clear out everything.
    CnuConfig.reload(true)

    # Reload delay
    CnuConfig._reload_delay = -1
    # CnuConfig._verbose = true
    CnuConfig._config_file_loaded = nil

    # Get the name of a config file to touch.
    assert cf1 = CnuConfig._get_config_files("test")
    assert cf1 = cf1[0][2]
      
    v = nil
    th = nil
    CnuConfig.disable_reload do 
      # Make sure first access works inside disable reload.
      assert th = CnuConfig.test
      assert_equal "foo", v = CnuConfig.test.hash_1.foo
      CnuConfig._config_file_loaded = nil

      # Get access again and insure that file was not reloaded.
      assert_equal v, CnuConfig.test.hash_1.foo
      assert th.object_id == CnuConfig.test.object_id
      assert ! CnuConfig._config_file_loaded
  
      # STDERR.puts "touching #{cf1.inspect}"
      FileUtils.touch(cf1)

      assert_equal v, CnuConfig.test.hash_1.foo
      assert th.object_id == CnuConfig.test.object_id
      assert ! CnuConfig._config_file_loaded
    end

    # STDERR.puts "reload allowed"
    assert ! CnuConfig._config_file_loaded
    assert th.object_id != CnuConfig.test.object_id
    assert_equal v, CnuConfig.test.hash_1.foo

    assert CnuConfig._config_file_loaded
    assert_equal v, CnuConfig.test.hash_1.foo
     

    # Restore reload_delay
    CnuConfig._reload_delay = false
    CnuConfig._verbose = false
  end


  def test_hash_merge
    assert_equal "foo", CnuConfig.test.hash_1.foo
    assert_equal "baz", CnuConfig.test.hash_1.bar
    assert_equal "bok", CnuConfig.test.hash_1.bok
    assert_equal "zzz", CnuConfig.test.hash_1.zzz
  end


  def test_array
    assert_equal [ 'a', 'b', 'c', 'd' ], CnuConfig.test.array_1
  end


  def test_index
    assert_kind_of Hash, CnuConfig.get_config_file(:test)
  end


  def test_config_files
    assert_kind_of Array, cf = CnuConfig._get_config_files("test").select{|x| x[3]}
    # STDERR.puts "cf = #{cf.inspect}"

    if ENV['CNU_CONFIG_OVERLAY']
      assert_equal 3, cf.size
    else
      assert_equal 2, cf.size
    end

    assert_equal 4, cf[0].size
    assert_equal "test", cf[0][0]
    assert_equal "test", cf[0][1]

    assert_equal 4, cf[1].size
    if ENV['CNU_CONFIG_OVERLAY'] == 'gb'
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
    CnuConfig.reload(true)

    cf1 = CnuConfig._config_files("test")
    cf2 = CnuConfig._get_config_files("test")
    cf3 = CnuConfig._config_files("test")

    file_to_touch = cf1[1][2]

    # Check that _config_files is cached.
    # STDERR.puts "cf1 = #{cf1.object_id.inspect}"
    # STDERR.puts "cf2 = #{cf2.object_id.inspect}"
    assert cf1.object_id != cf2.object_id
    assert cf1.object_id == cf3.object_id

    # STDERR.puts "cf1 = #{cf1.inspect}"
    # STDERR.puts "cf2 = #{cf2.inspect}"
    # Check that config_changed? is false, until touch.
    assert cf1.object_id != cf2.object_id
    assert_equal cf1, cf2
    assert_equal false, CnuConfig.config_changed?("test")

    # Touch a file.
    # $stderr.puts "file_to_touch = #{file_to_touch.inspect}"
    FileUtils.touch(file_to_touch)
    cf2 = CnuConfig._get_config_files("test")
    # Ensure that files were not reloaded until reload(true) below.
    assert cf1.object_id != cf2.object_id
    assert ! (cf1 === cf2)
    assert_equal true, CnuConfig.config_changed?("test")

    # Pull config again.
    CnuConfig.reload(true)
    cf3 = CnuConfig._config_files("test")
    cf2 = CnuConfig._get_config_files("test")
    # $stderr.puts "cf1.object_id = #{cf1.object_id}"
    # $stderr.puts "cf2.object_id = #{cf2.object_id}"
    # $stderr.puts "cf3.object_id = #{cf3.object_id}"
    # STDERR.puts "cf3 = #{cf1.inspect}"
    # STDERR.puts "cf2 = #{cf2.inspect}"

    # Insure that the list of files actually changed:
    assert cf1.object_id != cf3.object_id
    assert !(cf3 === cf1)
    assert (cf3 === cf2)
    assert_equal false, CnuConfig.config_changed?("test")

    # Pull config again, expect no changes.
    cf4 = CnuConfig._config_files("test")
    # STDERR.puts "cf3 = #{cf1.inspect}"
    # STDERR.puts "cf2 = #{cf2.inspect}"
    assert cf3.object_id == cf4.object_id
    assert CnuConfig._config_files("test")
    assert_equal false, CnuConfig.config_changed?("test")
 
  end


  def test_check_reload_disabled
    CnuConfig.reload(true)

    assert_kind_of Array, CnuConfig._config_files('test')
    
    CnuConfig._reload_disabled = true

    assert_kind_of Array, CnuConfig.load_config_files('test')

    CnuConfig._reload_disabled = nil
  end


  def test_on_load_callback
    # STDERR.puts "test_on_load_callback"

    CnuConfig.reload(true)
    # CnuConfig._verbose = 1

    cf1 = CnuConfig._config_files("test")

    assert_equal "foo", CnuConfig.test.hash_1.foo

    sleep 1

    called_back = 0

    CnuConfig.on_load(:test) do
      called_back += 1
      # STDERR.puts "on_load #{called_back}"
    end

    assert_equal 1, called_back

    assert_equal "foo", CnuConfig.test.hash_1.foo

    
    # STDERR.puts "Not expecting config change."
    assert_nil CnuConfig.check_config_changed
    assert_equal "foo", CnuConfig.test.hash_1.foo
    assert_equal 1, called_back

    file = cf1[0][2]
    # STDERR.puts "Touching file #{file.inspect}"
    File.chmod(0644, file)
    FileUtils.touch(file)
    File.chmod(0444, file)

    # STDERR.puts "Expect config change."
    assert_not_nil CnuConfig.check_config_changed
    assert_equal "foo", CnuConfig.test.hash_1.foo
    assert_equal 2, called_back

    # STDERR.puts "Not expecting config change."
    assert_nil CnuConfig.check_config_changed
    assert_equal "foo", CnuConfig.test.hash_1.foo
    assert_equal 2, called_back

    # STDERR.puts "test_on_load_callback: END"
  end


  def test_overlay_by_name
    assert_equal nil,   CnuConfig._overlay

    assert_equal "foo", CnuConfig.test.hash_1.foo
    assert_equal "foo", CnuConfig.test_GB.hash_1.foo

    assert_equal "bok", CnuConfig.test.hash_1.bok
    assert_equal "GB",  CnuConfig.test_GB.hash_1.bok

    assert_equal nil,   CnuConfig.test.hash_1.gb
    assert_equal "GB",  CnuConfig.test_GB.hash_1.gb
  end


  def test_overlay_change
    begin
      CnuConfig._overlay = 'gb'
      
      assert_equal "foo", CnuConfig.test.hash_1.foo
      assert_equal "foo", CnuConfig.test_GB.hash_1.foo
      assert_equal "foo", CnuConfig.test_US.hash_1.foo
      
      assert_equal "GB",  CnuConfig.test.hash_1.bok
      assert_equal "GB",  CnuConfig.test_GB.hash_1.bok
      assert_equal "US",  CnuConfig.test_US.hash_1.bok
      
      assert_equal "GB",  CnuConfig.test.hash_1.gb
      assert_equal "GB",  CnuConfig.test_GB.hash_1.gb
      assert_equal nil,   CnuConfig.test_US.hash_1.gb
      
      CnuConfig._overlay = 'us'
      
      assert_equal "foo", CnuConfig.test.hash_1.foo
      assert_equal "foo", CnuConfig.test_GB.hash_1.foo
      assert_equal "foo", CnuConfig.test_US.hash_1.foo
      
      assert_equal "US", CnuConfig.test.hash_1.bok
      assert_equal "GB", CnuConfig.test_GB.hash_1.bok
      assert_equal "US", CnuConfig.test_US.hash_1.bok
      
      assert_equal  nil,  CnuConfig.test.hash_1.gb
      assert_equal "GB",  CnuConfig.test_GB.hash_1.gb
      assert_equal  nil,  CnuConfig.test_US.hash_1.gb
 
      CnuConfig._overlay = nil

    ensure
      CnuConfig._overlay = nil
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
        CnuConfig.test.hash_1.foo
      end
    end
    STDERR.puts "\n#{n}.times =>#{bm}\n"
  end

end # class

