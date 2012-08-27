require 'active_config'
module ActiveConfigRails
  def init_conf
    if Object.const_defined? :CONF
      Object.send(:remove_const, :CONF)
    end
  
    etc_dir = File.dirname(File.expand_path(__FILE__)) + '/../../etc'
    Object.const_set(:CONF,ActiveConfig.new(:path => etc_dir))
  end
  module_function :init_conf
end
ActiveConfigRails.init_conf

if CONF.rails && CONF.rails.env and not ENV['ACTIVE_CONFIG_FORCE_RAILS_ENV']
  ENV['ACTIVE_CONFIG_FORCE_RAILS_ENV']=CONF.rails.env
  ENV['RAILS_ENV']||=CONF.rails.env
  ActiveConfigRails.init_conf
end

if CONF.rails && CONF.rails.force_env and not ENV['ACTIVE_CONFIG_FORCE_RAILS_ENV']
  ENV['ACTIVE_CONFIG_FORCE_RAILS_ENV']=CONF.rails.force_env
  if ENV['RAILS_ENV']
    STDERR.puts "WARNING:  ACTIVE CONFIG IS OVERRIDING YOUR ENVIRONMENT VARIABLE RAILS_ENV!\nPLEASE FIX YOUR rails.yml!"
  end 
  ENV['RAILS_ENV']=CONF.rails.force_env
  ActiveConfigRails.init_conf
end

