require 'socket'
require 'yaml'
require 'active_config/hash_weave' # Hash#weave
require 'rubygems'
require 'active_config/hash_config'
require 'active_config/suffixes'
require 'erb'


##
# See LICENSE.txt for details
#
#=ActiveConfig
#
# * Provides dottable, hash, array, and argument access to YAML 
#   configuration files
# * Implements multilevel caching to reduce disk accesses
# * Overlays multiple configuration files in an intelligent manner
#
# Config file access example:
#  Given a configuration file named test.yaml and test_local.yaml
#  test.yaml:
# ...
# hash_1:
#   foo: "foo"
#   bar: "bar"
#   bok: "bok"
# ...
# test_local.yaml:
# ...
# hash_1:
#   foo: "foo"
#   bar: "baz"
#   zzz: "zzz"
# ...
#
#  irb> ActiveConfig.test
#  => {"array_1"=>["a", "b", "c", "d"], "perform_caching"=>true,
#  "default"=>"yo!", "lazy"=>true, "hash_1"=>{"zzz"=>"zzz", "foo"=>"foo",
#  "bok"=>"bok", "bar"=>"baz"}, "secure_login"=>true, "test_mode"=>true}
#
#  --Notice that the hash produced is the result of merging the above
#  config files in a particular order
#
#  The overlay order of the config files is defined by ActiveConfig._get_file_suffixes:
#  * nil
#  * _local
#  * _config
#  * _local_config
#  * _{environment} (.i.e _development)
#  * _{environment}_local (.i.e _development_local)
#  * _{hostname} (.i.e _whiskey)
#  * _{hostname}_config_local (.i.e _whiskey_config_local)
#
#  ------------------------------------------------------------------
#  irb> ActiveConfig.test_local
#  => {"hash_1"=>{"zzz"=>"zzz", "foo"=>"foo", "bar"=>"baz"}, "test_mode"=>true} 
#

class ActiveConfig
  EMPTY_ARRAY = [ ].freeze unless defined? EMPTY_ARRAY
  def _suffixes
    @suffixes_obj
  end
  # ActiveConfig.new take options from a hash (or hash like) object.
  # Valid keys are:
  #   :path           :  Where it can find the config files, defaults to ENV['ACTIVE_CONFIG_PATH'], or RAILS_ROOT/etc
  #   :root_file      :  Defines the file that holds "top level" configs. (ie active_config.key).  Defaults to "global"
  #   :suffixes       :  Either a suffixes object, or an array of suffixes symbols with their priority.  See the ActiveConfig::Suffixes object
  #   :config_refresh :  How often we should check for update config files
  #
  #                 
  #FIXME TODO
  def initialize opts={}
    @config_path=opts[:path] || ENV['ACTIVE_CONFIG_PATH'] || (defined?(RAILS_ROOT) ? File.join(RAILS_ROOT,'etc') : nil)
    @opts=opts
    if opts[:one_file]
    @root_file=@config_path 
    else
    @root_file=opts[:root_file] || 'global' 
      if ActiveConfig::Suffixes===opts[:suffixes]
        @suffixes_obj = opts[:suffixes] 
      end
    end
    @suffixes_obj ||= Suffixes.new self, opts[:suffixes]
    @suffixes_obj.ac_instance=self
    @config_refresh = 
      (opts.has_key?(:config_refresh) ? opts[:config_refresh].to_i : 300)
    @on_load = { }
    self._flush_cache
  end
  def _config_path
    @config_path_ary ||=
      begin
        path_sep = (@config_path =~ /;/) ? /;/ : /:/ # Make Wesha happy
        path = @config_path.split(path_sep).reject{ | x | x.empty? }
        path.map!{|x| x.freeze }.freeze
      end
  end

  # DON'T CALL THIS IN production.
  def _flush_cache *types
    if types.size == 0 or types.include? :hash
      @cache_hash = { }
      @hash_times = Hash.new(0)
    end
    if types.size == 0 or types.include? :file
      @file_times = Hash.new(0)
      @file_cache = { }
    end
    self
  end

  def _reload_disabled=(x)
    @reload_disabled = x.nil? ? false : x
  end

  def _reload_delay=(x)
    @config_refresh = x || 300
  end

  def _verbose=(x)
    @verbose = x.nil? ? false : x;
  end

  ##
  # Get each config file's yaml hash for the given config name, 
  # to be merged later. Files will only be loaded if they have 
  # not been loaded before or the files have changed within the 
  # last five minutes, or force is explicitly set to true.
  #
  # If file contains the comment:
  #
  #   # ACTIVE_CONFIG:ERB
  #
  # It will be run through ERb before YAML parsing
  # with the following object bound:
  #
  #   active_config.config_file => <<the name of the config.yml file>>
  #   active_config.config_directory => <<the directory of the config.yml>>
  #   active_config.config_name => <<the config name>>
  #   active_config.config_files => <<Array of config files to be parsed>>
  #
  def _load_config_files(name, force=false)
    name = name.to_s
    now = Time.now

    # Get array of all the existing files file the config name.
    config_files = _config_files(name)
    
    #$stderr.puts config_files.inspect
    # Get all the data from all yaml files into as hashes
    _fire_on_load(name)
    hashes = config_files.collect do |f|
      filename=f
      val=nil
      mod_time=nil
      next unless File.exists?(filename)
      next(@file_cache[filename]) unless (mod_time=File.stat(filename).mtime) != @file_times[filename]
      begin
      File.open( filename ) { | yf |
        val = yf.read
      }
      # If file has a # ACTIVE_CONFIG:ERB comment,
      # Process it as an ERb first.
      if /^\s*#\s*ACTIVE_CONFIG\s*:\s*ERB/i.match(val)
        # Prepare a object visible from ERb to
        # allow basic substitutions into YAMLs.
        active_config = HashWithIndifferentAccess.new({
          :config_file => filename,
          :config_directory => File.dirname(filename),
          :config_name => name,
          :config_files => config_files,
        })
        val = ERB.new(val).result(binding)
      end
      # Read file data as YAML.
      val = YAML::load(val)
      # STDERR.puts "ActiveConfig: loaded #{filename.inspect} => #{val.inspect}"
      (@config_file_loaded ||= { })[name] = config_files
      rescue Exception => e
      end
      @file_cache[filename]=val
      @file_times[filename]=mod_time
      @file_cache[filename]
    end
    hashes.compact
  end


  def get_config_file(name)
    # STDERR.puts "get_config_file(#{name.inspect})"
    name = name.to_s # if name.is_a?(Symbol)
    now = Time.now
    return @cache_hash[name.to_sym] if 
      (now.to_i - @hash_times[name.to_sym]  < @config_refresh) 
    # return cached if we have something cached and no reload_disabled flag
    return @cache_hash[name.to_sym] if @cache_hash[name.to_sym] and @reload_disabled
    # $stderr.puts "NOT USING CACHED AND RELOAD DISABLED" if @reload_disabled
    @cache_hash[name.to_sym]=begin
      x = _config_hash(name)
      @hash_times[name.to_sym]=now.to_i
      x
    end
  end

  ## 
  # Returns a list of all relavant config files as specified
  # by the suffixes object.
  def _config_files(name) 
    return [name] if File.exists?(name) and not File.directory?(name)
    _suffixes.for(name).inject([]) do | files,name_x |
      _config_path.reverse.inject(files) do |files, dir |
        files <<  File.join(dir, name_x.to_s + '.yml')
      end
    end
  end

  def _config_hash(name)
    unless result = @cache_hash[name]
      result = @cache_hash[name] = 
        HashConfig._make_indifferent_and_freeze(
          _load_config_files(name).inject({ }) { | n, h | n.weave(h, false) })
    end
    #$stderr.puts result.inspect
    result
  end


  ##
  # Register a callback when a config has been reloaded.
  #
  # The config :ANY will register a callback for any config file change.
  #
  # Example:
  #
  #   class MyClass 
  #     @my_config = { }
  #     ActiveConfig.on_load(:global) do 
  #       @my_config = { } 
  #     end
  #     def my_config
  #       @my_config ||= something_expensive_thing_on_config(ACTIVEConfig.global.foobar)
  #     end
  #   end
  #
  def on_load(*args, &blk)
    args << :ANY if args.empty?
    proc = blk.to_proc

    # Call proc on registration.
    proc.call()

    # Register callback proc.
    args.each do | name |
      name = name.to_s
      (@on_load[name] ||= [ ]) << proc
    end
  end

  # Do reload callbacks.
  def _fire_on_load(name)
    callbacks = 
      (@on_load['ANY'] || EMPTY_ARRAY) + 
      (@on_load[name] || EMPTY_ARRAY)
    callbacks.uniq!
    STDERR.puts "_fire_on_load(#{name.inspect}): callbacks = #{callbacks.inspect}" if @verbose && ! callbacks.empty?
    callbacks.each do | cb |
      cb.call()
    end
  end

  def _check_config_changed(iname=nil)
    iname=iname.nil? ?  @cache_hash.keys.dup : [*iname]
    ret=iname.map{ | name |
    # STDERR.puts "ActiveConfig: config changed? #{name.inspect} reload_disabled = #{@reload_disabled}" if @verbose
    if config_changed?(name) && ! @reload_disabled 
      STDERR.puts "ActiveConfig: config changed #{name.inspect}" if @verbose
      if @cache_hash[name]
        @cache_hash[name] = nil

        # force on_load triggers.
        name
      end
    end
    }.compact
    return nil if ret.empty?
    ret
  end

  def with_file(name, *args)
    # STDERR.puts "with_file(#{name.inspect}, #{args.inspect})"; result = 
    args.inject(get_config_file(name)) { | v, i | 
      # STDERR.puts "v = #{v.inspect}, i = #{i.inspect}"
      case v
      when Hash
        v[i.to_s]
      when Array
        i.is_a?(Integer) ? v[i] : nil
      else
        nil
      end
    }
    # STDERR.puts "with_file(#{name.inspect}, #{args.inspect}) => #{result.inspect}"; result
  end
 
  #If you are using this in production code, you fail.
  def reload(force = false)
    if force || ! @reload_disabled
      _flush_cache
    end
    nil
  end

  ## 
  # Disables any reloading of config,
  # executes &block, 
  # calls check_config_changed,
  # returns result of block
  #
  def disable_reload(&block)
    # This should increment @reload_disabled on entry, decrement on exit.
    # -- kurt 2007/06/12
    result = nil
    reload_disabled_save = @reload_disabled
    begin
      @reload_disabled = true
      result = yield
    ensure
      @reload_disabled = reload_disabled_save
      _check_config_changed unless @reload_disabled
    end
    result
  end

  ##
  # Gets a value from the global config file
  #
  def [](key, file=@root_file)
    get_config_file(file)[key]
  end

  ##
  # Short-hand access to config file by its name.
  #
  # Example:
  #
  #   ActiveConfig.global(:foo) => ActiveConfig.with_file(:global).foo
  #   ActiveConfig.global.foo   => ActiveConfig.with_file(:global).foo
  #
  def method_missing(method, *args)
    return self[method.to_sym] if @opts[:one_file] 
    if method.to_s=~/^_(.*)/
      _flush_cache 
      return @suffixes.send($1, *args)
    else 
      value = with_file(method, *args)
      value
    end
  end
end

