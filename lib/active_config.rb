require 'socket'
require 'yaml'
require 'hash_weave' # Hash#weave
# REMOVE DEPENDENCY ON active_support.
require 'rubygems'
require 'active_support'
require 'active_support/core_ext'
require 'active_support/core_ext/hash/indifferent_access'
require 'hash_config'
require 'suffixes'
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
  attr :_suffix_symbols
  EMPTY_ARRAY = [ ].freeze unless defined? EMPTY_ARRAY
  EMPTY_HASH = { }.freeze unless defined? EMPTY_HASH

  # The cached general suffix list.
  # Invalidated if @@_mode changes.

  #There is a suffixes object which handles all the options and structure
  #for suffixes
  def _suffixes
    @_suffixes_obj||=Suffixes.new
  end

  # Returns a list of directories to search for
  # configuration files.
  # 
  # Can be controlled via ENV['ACTIVE_CONFIG_PATH']
  # Defaults to [ CONFIG_ROOT ].
  #
  # Example:
  #   ACTIVE_CONFIG_PATH="$HOME/work/config:CONFIG_ROOT" script/console
  #
  def initialize opts={}
    @config_path=opts[:path] if opts[:path]
    @root_file=opts[:root_file] if opts[:root_file]
    @suffixes = opts[:suffixes] if opts[:suffixes]
  end
  def _root_file
    @root_file || 'global'
  end
  def _root_file= rootfile
    @root_file=rootfile
  end
  def _config_path
    @config_path||= ENV['ACTIVE_CONFIG_PATH']
  end
  def _config_path_ary
    @config_path_ary ||=
      begin
        path_sep = (_config_path =~ /;/) ? /;/ : /:/ # Make Wesha happy
        path = _config_path.split(path_sep).reject{ | x | x.empty? }
        path = 
          path.collect! do | x | 
            x.freeze
          end
        path.freeze
        path
      end
  end


  # Returns a list of suffixes to try for a given config name.
  #
  # This allows code to specifically ask for config overlays
  # for a particular locale.
  #
  def _get_file_suffixes(name)
    name = name.to_s
    @@suffixes[name] ||= 
      [name, _suffixes.suffixes]
  end


  # Hash of suffixes for a given config name.
  # @@suffixes['name'] vs @@suffix['name_GB']
  @@suffixes = { }

  # Hash of yaml file names and their respective contents,  
  # last modified time, and the last time it was loaded.
  # @@cache[filename] = [yaml_contents, mod_time, time_loaded]
  @@cache = {}

  # Hash of config file base names and their existing filenames
  # including the suffixes.  
  # @@cache_files['global'] = ['global.yml', 'global_local.yml', 'global_whiskey.yml']
  @@cache_files = {}

  # Hash of config base name and the contents of all its respective 
  # files merged into hashes. This hash holds the data that is 
  # accessed when ActiveConfig is called. This gets re-created each time
  # the config files are loaded.
  # @@cache_hash['global'] = config_hash
  @@cache_hash = { }

  # The hash holds the same info as @@cache_hash, but it is only
  # loaded once. If reload is disabled, data will from this hash 
  # will always be passed back when ActiveConfig is called.
  @@cache_config_files = { } # Keep around incase reload_disabled.

  # Hash of config base name and the last time it was checked for
  # update.
  # @@last_auto_check['global'] = Time.now
  @@last_auto_check = { }

  # Hash of callbacks Procs for when a particular config file has changed.
  @@on_load = { }

  # DON'T CALL THIS IN production.
  def _flush_cache
    @suffixes = nil
    @@suffixes = { }
    @@cache = { } 
    @@cache_files = { } 
    @@cache_hash = { }
    @@last_auto_check = { }
    self
  end

  # Flag indicating whether or not reload should be executed.
  @@reload_disabled = false
  def _reload_disabled=(x)
    @@reload_disabled = x.nil? ? false : x
  end

  # The number of seconds between reloading of config files
  # and automatic reload checks.
  @@reload_delay = 300
  def _reload_delay=(x)
    @@reload_delay = x ||
      300
  end

  # Flag indicating whether or not to log errors that occur 
  # in the process of handling config files.
  @@verbose = false
  def _verbose=(x)
    @@verbose = x.nil? ? false : x;
  end

  # Helper methods for white-box testing and debugging.
  
  # A hash of each file that has been loaded.
  # Can be used for white-box testing or debugging.
  @@config_file_loaded = nil
  def _config_file_loaded=(x)
    @@config_file_loaded = x
  end
  def _config_file_loaded
    @@config_file_loaded
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
  def load_config_files(name, force=false)
    name = name.to_s # if name.is_a?(Symbol)

    # Return last config file hash list loaded,
    # if reload is disabled and files have already been loaded.
    return @@cache_config_files[name] if 
      @@reload_disabled && 
      @@cache_config_files[name]

    now = Time.now

    # Get array of all the existing files file the config name.
    config_files = _get_config_files(name)
    # STDERR.puts "load_config_files(#{name.inspect})"
    
    # Get all the data from all yaml files into as hashes
    hashes = config_files.collect do |f|
      name, name_x, filename, mtime = *f

      # Get the cached file info the specific file, if 
      # it's been loaded before.
      val, last_mtime, last_loaded = @@cache[filename] 

      if @@verbose
        STDERR.puts "f = #{f.inspect}"
        STDERR.puts "cache #{name_x} filename = #{filename.inspect}"
        STDERR.puts "cache #{name_x} val = #{val.inspect}"
        STDERR.puts "cache #{name_x} last_mtime = #{last_mtime.inspect}"
        STDERR.puts "cache #{name_x} last_loaded = #{last_loaded.inspect}"
      end

      # Load the file if its never been loaded or its been more 
      # than 5 minutes since last load attempt.
      if val == nil || 
        now - last_loaded > @@reload_delay
        if force || 
            val == nil || 
            mtime != last_mtime
          
          # mtime is nil if file does not exist.
          if mtime 
            begin
            File.open( filename ) do | yf |
              STDERR.puts "\nActiveConfig: loading #{filename.inspect}" if @@verbose
              # Read raw file data.
              val = yf.read

              # If file has a # ACTIVE_CONFIG:ERB comment,
              # Process it as an ERb first.
              if /^\s*#\s*ACTIVE_CONFIG\s*:\s*ERB/i.match(val)
                # Prepare a object visible from ERb to
                # allow basic substitutions into YAMLs.
                active_config = {
                  :config_file => filename,
                  :config_directory => File.dirname(filename),
                  :config_name => name,
                  :config_files => config_files,
                }
                active_config = _make_indifferent(active_config)

                val = ERB.new(val).result(binding)
              end

              # Read file data as YAML.
              val = YAML::load(val)
              # STDERR.puts "ActiveConfig: loaded #{filename.inspect} => #{val.inspect}"
              (@@config_file_loaded ||= { })[name] = config_files
            end
            rescue Exception => err
              raise Exception, "while loading #{filename.inspect}: #{err.inspect}\n  #{err.backtrace.join("  \n")}"
            end
          end
            
          # Save cached config file contents, and mtime.
          @@cache[filename] = [ val.nil? ? val : val.dup, mtime, now ]
          # STDERR.puts "cache[#{filename.inspect}] = #{@@cache[filename].inspect}" if @@verbose && name_x == 'test'

          # Flush merged hash cache.
          @@cache_hash[name] = nil
                 
          # Config files changed or disappeared.
          @@cache_files[name] = config_files

         end
      end

      val
    end
    hashes.compact!

    # STDERR.puts "load_config_files(#{name.inspect}) => #{hashes.inspect}"

    # Keep last loaded config files around in case @@reload_dsabled.
    @@cache_config_files[name] = hashes

    hashes
  end


  ## 
  # Returns a list of all relavant config files as specified
  # by _get_file_suffixes list.
  # Each element is an Array, containing:
  #   [ "the-top-level-config-name",
  #     "the-suffixed-config-name",
  #     "/the/absolute/path/to/yaml.yml",
  #     # The mtime of the yml file or nil, if it doesn't exist.
  #   ]
  def _get_config_files(name) 
    files = [ ]
    # alexg: splatting *suffix allows us to deal with multipart suffixes 
    # The order these get returned is the order of
    # priority of override.
    name_no_overlay, suffixes = _get_file_suffixes(name)
    suffixes.map { | suffix | [ name_no_overlay, *suffix ].compact.join('_') }.each do | name_x |
      _config_path_ary.reverse.each do | dir |
        filename = filename_for_name(name_x, dir)
        files <<
        [ name,
          name_x, 
          filename, 
          File.exist?(filename) ? File.stat(filename).mtime : nil, 
        ]
      end
    end

    files
  end

  ##
  # Return the cached config file information for the given config name.
  def _config_files(name)
    @@cache_files[name] ||= _get_config_files(name)
  end

  ##
  # Returns whether or not the config for the given config name has changed 
  # since it was last loaded.
  #
  # Returns true if any files for config have changes since
  # last load.
  def config_changed?(name)
    # STDERR.puts "config_changed?(#{name.inspect})"
    name = name.to_s # if name.is_a?(Symbol)
    ! (@@cache_files[name] === _get_config_files(name))
  end

  ## 
  # Get the merged config hash for the named file.
  #
  def config_hash(name)
    name = name.to_s # if name.is_a?(Symbol)
    _config_hash(name)
  end


  ## 
  # Returns a cached indifferent access faker hash merged
  # from all config files for a name.
  #
  def _config_hash(name)
#    $stderr.puts load_config_files(name).inspect
    # STDERR.puts "_config_hash(#{name.inspect})"; result = 
    unless result = @@cache_hash[name]
      result = @@cache_hash[name] = 
        _make_frozen(
                     _make_indifferent(
                          _merge_hashes(
                                        load_config_files(name)))
                     )

      STDERR.puts "_config_hash(#{name.inspect}): reloaded" if @@verbose
      
    end

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
  #     @@my_config = { }
  #     ActiveConfig.on_load(:global) do 
  #       @@my_config = { } 
  #     end
  #     def my_config
  #       @@my_config ||= something_expensive_thing_on_config(ACTIVEConfig.global.foobar)
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
      (@@on_load[name] ||= [ ]) << proc
    end
  end


  # Do reload callbacks.
  def _fire_on_load(name)
    callbacks = 
      (@@on_load['ANY'] || EMPTY_ARRAY) + 
      (@@on_load[name] || EMPTY_ARRAY)
    callbacks.uniq!
    STDERR.puts "_fire_on_load(#{name.inspect}): callbacks = #{callbacks.inspect}" if @@verbose && ! callbacks.empty?
    callbacks.each do | cb |
      cb.call()
    end
  end


  # If config files have changed,
  # Caches are flushed, on_load triggers are run.
  def check_config_changed(name = nil)
    changed = [ ]

    # STDERR.puts "check_config_changed(#{name.inspect})"
    if name == nil
      @@cache_hash.keys.dup.each do | name |
        if _check_config_changed(name)
          changed << name
        end
      end
    else
      name = name.to_s #  if name.is_a?(Symbol)
      if _check_config_changed(name)
        changed << name
      end
    end
    STDERR.puts "check_config_changed(#{name.inspect}) => #{changed.inspect}" if @@verbose && ! changed.empty?

    changed.empty? ? nil : changed
  end


  def _check_config_changed(name)
    changed = false

    # STDERR.puts "ActiveConfig: config changed? #{name.inspect} reload_disabled = #{@@reload_disabled}" if @@verbose
    if config_changed?(name) && ! @@reload_disabled 
      STDERR.puts "ActiveConfig: config changed #{name.inspect}" if @@verbose
      if @@cache_hash[name]
        @@cache_hash[name] = nil

        # force on_load triggers.
        _fire_on_load(name)
      end

      changed = true
    end

    changed
  end


  ##
  # Returns a merge of hashes.
  #
  def _merge_hashes(hashes)
    hashes.inject({ }) { | n, h | n.weave(h, false) }
  end


  ## 
  # Recursively makes hashes into frozen IndifferentAccess ConfigFakerHash
  # Arrays are also traversed and frozen.
  #
  def _make_indifferent(x)
    case x
    when HashConfig
      unless x.frozen?
        x.each_pair do | k, v |
          x[k] = _make_indifferent(v)
        end
      end
      x
    when Hash
      unless x.frozen?
        x = HashConfig.new.merge!(x)
        x.each_pair do | k, v |
          x[k] = _make_indifferent(v)
        end
      end
      # STDERR.puts "x = #{x.inspect}:#{x.class}"
    when Array
      unless x.frozen?
        x.collect! do | v |
          _make_indifferent(v)
        end
      end
    end

    x
  end

  # Arrays are also traversed and frozen.
  def _make_frozen(x)
    case x
    when Hash
      unless x.frozen?
        x.each_pair do | k, v |
          _make_frozen(v)
        end
        x.freeze
      end
      # STDERR.puts "x = #{x.inspect}:#{x.class}"
    when Array
      unless x.frozen?
        x.collect! do | v |
          _make_frozen(v)
        end
        x.freeze
      end
    # Freeze Strings.
    when String
      x.freeze
    end

    x
  end

  # Returns a new configuration hash that is unfrozen.
  def _unfreeze(x)
    case x
    when Hash
      if x.frozen?
        x = HashConfig.new.merge!(x)
      end
      x.each_pair do | k, v |
        x[k] = _unfreeze(v)
      end
      # STDERR.puts "x = #{x.inspect}:#{x.class}"
    when Array
      if x.frozen?
        x = x.dup
      end
      x.collect! do | v |
        _unfreeze(v)
      end
    # Freeze Strings.
    when String
      if x.frozen?
        x = x.dup
      end
    end
    
    x
  end


  ##
  # Gets a value from the global config file
  #
  def [](key, file=_root_file)
    get_config_file(file)[key]
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
  
  ##
  # Get the merged config hash.
  # Will auto check every 5 minutes, for longer running apps.
  #
  def get_config_file(name)
    # STDERR.puts "get_config_file(#{name.inspect})"
    name = name.to_s # if name.is_a?(Symbol)
    now = Time.now
    if (! @@last_auto_check[name]) || (now - @@last_auto_check[name]) > @@reload_delay
      @@last_auto_check[name] = now
      check_config_changed(name)
    end
    # result = 
    _config_hash(name)
    # STDERR.puts "get_config_file(#{name.inspect}) => #{result.inspect}"; result
  end
  
  def with_file_sym(file, *args)
    with_file(file, *args)
  end

  def global_sym(*args)
    with_file(_root_file, *args)
  end


  ## 
  # Disables any reloading of config,
  # executes &block, 
  # calls check_config_changed,
  # returns result of block
  #
  def disable_reload(&block)
    # This should increment @@reload_disabled on entry, decrement on exit.
    # -- kurt@cashnetusa.com 2007/06/12
    result = nil
    reload_disabled_save = @@reload_disabled
    begin
      @@reload_disabled = true
      result = yield
    ensure
      @@reload_disabled = reload_disabled_save
      check_config_changed unless @@reload_disabled
    end
    result
  end


  ##
  # Creates a dottable hash for all Hash objects, recursively.
  #
  def create_dottable_hash(value)
    _make_frozen(_make_indifferent(value))
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
    if method.to_s=~/^_(.*)/
#    $stderr.puts "AC MM #{method}"
#      $stderr.puts method
      _flush_cache 
      return _suffixes.send($1, *args)
    else 
      value = with_file(method, *args)
      value
    end
  end

  #If you are using this in production code, you fail.
  def reload(force = false)
    if force || ! @@reload_disabled
      return unless ['development', 'integration'].include?(_mode)
      _flush_cache
    end
    nil
  end
                    
  protected

  ##
  # Get complete file name, including file path for the given config name
  # and directory.
  #
  def filename_for_name(name, dir = _config_path_ary[0])
    File.join(dir, name.to_s + '.yml')
  end
end

