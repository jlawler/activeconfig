
class ActiveConfig
  class HashConfig < Hash
  def initialize(constructor = {})
    super()
    update(constructor)
  end
  def default(key = nil)
    if key.is_a?(Symbol) && include?(key = key.to_s)
      self[key]
    else
      super
    end
  end

  alias_method :regular_writer, :[]= unless method_defined?(:regular_writer)
  alias_method :regular_update, :update unless method_defined?(:regular_update)

  # Assigns a new value to the hash:
  #
  #   hash = HashWithIndifferentAccess.new
  #   hash[:key] = "value"
  #
  def []=(key, value)
    regular_writer(convert_key(key), convert_value(value))
  end

  # Updates the instantized hash with values from the second:
  # 
  #   hash_1 = HashWithIndifferentAccess.new
  #   hash_1[:key] = "value"
  # 
  #   hash_2 = HashWithIndifferentAccess.new
  #   hash_2[:key] = "New Value!"
  # 
  #   hash_1.update(hash_2) # => {"key"=>"New Value!"}
  # 
  def update(other_hash)
    other_hash.each_pair { |key, value| regular_writer(convert_key(key), convert_value(value)) }
    self
  end

  alias_method :merge!, :update

  # Checks the hash for a key matching the argument passed in:
  #
  #   hash = HashWithIndifferentAccess.new
  #   hash["key"] = "value"
  #   hash.key? :key  # => true
  #   hash.key? "key" # => true
  #
  def key?(key)
    super(convert_key(key))
  end

  alias_method :include?, :key?
  alias_method :has_key?, :key?
  alias_method :member?, :key?

  # Fetches the value for the specified key, same as doing hash[key]
  def fetch(key, *extras)
    super(convert_key(key), *extras)
  end

  # Returns an array of the values at the specified indices:
  #
  #   hash = HashWithIndifferentAccess.new
  #   hash[:a] = "x"
  #   hash[:b] = "y"
  #   hash.values_at("a", "b") # => ["x", "y"]
  #
  def values_at(*indices)
    indices.collect {|key| self[convert_key(key)]}
  end

  # Returns an exact copy of the hash.
  def dup
    self.class.new(self)
  end

  # Merges the instantized and the specified hashes together, giving precedence to the values from the second hash
  # Does not overwrite the existing hash.
  def merge(hash)
    self.dup.update(hash)
  end

  # Removes a specified key from the hash.
  def delete(key)
    super(convert_key(key))
  end

  # Convert to a Hash with String keys.
  def to_hash
    Hash.new(default).merge(self)
  end


    # HashWithIndifferentAccess#dup always returns HashWithIndifferentAccess!
    # -- kurt 2007/10/18
    def dup
      self.class.new(self)
    end

    def self._make_indifferent_and_freeze(x)
      _make_indifferent(x,:freeze => true)
    end
    def freeze!
      return false if self.frozen?
      self.each_pair do | k, v |
        self[self.class.recursive_freeze(k)] = self.class.recursive_freeze(v) 
      end
      self.freeze
      self 
    end
    def self.recursive_freeze x
      return x if x.frozen?
      case x
      when HashConfig,Hash
          x.each_pair do | k, v |
            x[recursive_freeze(k)] = recursive_freeze(v) 
          end
      when Array
        x.collect! {|v|freeze(v)}
      end
      x.freeze 
    end
    def self._make_indifferent(x,opts={})
      return x if  opts[:freeze] and x.frozen?
      case x
      when HashConfig
          x.each_pair do | k, v |
            x[k.freeze] = _make_indifferent(v,opts)
          end
      when Hash
        x = HashConfig.new.merge(x)
        x.each_pair do | k, v |
          x[k.freeze] = _make_indifferent(v,opts)
        end
        # STDERR.puts "x = #{x.inspect}:#{x.class}"
      when Array
        x.collect!  do | v |
          _make_indifferent(v,opts)
        end
      end

      x.freeze if opts[:freeze]
      x
    end

    # dotted notation can now be used with arguments (useful for creating mock objects)
    # in the YAML file the method name is a key (just like usual), argument(s)
    # form a nested key, and the value will get returned.
    #
    # For example loading to variable foo a yaml file that looks like:
    # customer:
    #   id: 12345678
    #   verified:
    #     phone: verified
    #     :address: info_not_available
    #     ? [name, employer]
    #     : not_verified
    # 
    # Allows the following calls:
    # foo.customer.id   --> 12345678
    # foo.customer.verified.phone  --> verified
    # foo.customer.verified("phone")  --> verified
    # foo.customer.verified("name", "employer")  --> not_verified
    # foo.customer.verified(:address) --> info_not_available
    #
    # Note that :address is specified as a symbol, where phone is just a string.
    # Depending on what kind of parameter the method being mocked out is going 
    # to be called with, define in the YAML file either a string or a symbol.  
    # This also works inside the composite array keys.
    def method_missing(method, *args)
      method = method.to_s
      if args.size==1 and method.to_s=~/=$/
        return  self[method.to_s.sub(/=$/,'')]=args[0]
      end
      args.inject(self[method]){|s,e|s and s[e]}
    end
    
    ## 
    # Why the &*#^@*^&$ isn't HashWithIndifferentAccess actually doing this?
    #
    def [](key)
      key = key.to_s if key.kind_of?(Symbol)
      super(key)
    end

    # HashWithIndifferentAccess#default is broken!
    define_method(:default_Hash, Hash.instance_method(:default))

    ##
    # Allow hash.default => hash['default']
    # without breaking Hash's usage of default(key)
    #
    @@no_key = [ :no_key ] # magically unique value.
    def default(key = @@no_key)
      key = key.to_s if key.is_a?(Symbol)
      key == @@no_key ? self['default'] : default_Hash(key == @@no_key ? nil : key)
    end
    
  protected
    def convert_key(key)
      key.kind_of?(Symbol) ? key.to_s : key
    end

    def convert_value(value)
      return value
    end

  end
end
