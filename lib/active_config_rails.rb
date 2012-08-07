
module ActiveConfigRails
  module Generators
    class InstallGenerator < ::Rails::Generators::Base
      namespace 'active_config:install'
      source_root File.expand_path('../active_config_rails/templates', __FILE__)

      def generate_config
        template 'active_config_initializer.rb', 'config/initializers/active_config.rb'
      end

      def insert_to_application
        ln = "require File.expand_path('../initializers/active_config', __FILE__)\n"
        prepend_to_file 'config/application.rb', ln
      end
      def convert_database_yaml
        empty_directory('etc')
        FileUtils.cp(relative_to_original_destination_root('config/database.yml'),'etc/database.yml')
        remove_file('config/database.yml')
        copy_file 'database.yml', 'config/database.yml'
        copy_file 'rails.yml', 'etc/rails.yml'


        #comment = "\n  # Set the logging destination(s)\n  %s\n"
        #insert_into_file 'config/environments/development.rb', comment % 'config.log_to = %w[stdout file]', :before => %r/^end\s*$/
        #insert_into_file 'config/environments/production.rb', comment % 'config.log_to = %w[file]', :before => %r/^end\s*$/
      end

    end
  end
end

