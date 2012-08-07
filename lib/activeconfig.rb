require 'active_config'
if Object.const_defined?(:Rails) && Object.const_get(:Rails).const_defined?(:Generators)
require 'active_config_rails'
end
