require 'rubygems'
require 'active_config'

class ActiveConfig::SuffixesWithOverlay < ActiveConfig::Suffixes
    def overlay= new_overlay
      symbols[:overlay]=(new_overlay.respond_to?(:upcase) ? new_overlay.upcase : new_overlay)
    end
    def initialize(*args)
      super
      @symbols[:overlay]=proc { |sym_table| ENV['ACTIVE_CONFIG_OVERLAY']}
      @priority=[
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
      [:hostname, :local_config],
      [:overlay, [:hostname, :local_config]]
    ]
    end
end
class CnuConfigClass < ActiveConfig
  attr :_overlay
  def _suffixes
    @_suffixes_obj||=Suffixes.new
  end
  def _overlay= x
    _suffixes.priority=[   
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
    super 
  end
  def _config_path
    @config_path||= ENV['CNU_CONFIG_PATH']
  end
end
CnuConfig=CnuConfigClass.new


