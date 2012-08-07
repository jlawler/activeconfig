require 'active_config'

if Object.const_defined? :CONF
  Object.send(:remove_const, :CONF)
end

etc_dir = File.dirname(File.expand_path(__FILE__)) + '/../../etc'
Object.const_set(:CONF,ActiveConfig.new(:path => etc_dir))

if CONF.rails.force_env and not ENV['ACTIVE_CONFIG_FORCE_RAILS_ENV']
  ENV['ACTIVE_CONFIG_FORCE_RAILS_ENV']=CONF.rails.force_env
  ENV['RAILS_ENV']=CONF.rails.force_env
end

