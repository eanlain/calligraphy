require 'rails/generators/base'

module Calligraphy
  module Generators
    class InstallGenerator < ::Rails::Generators::Base
      source_root File.expand_path('../../templates', __FILE__)

      desc 'Creates a Calligraphy initializer for your application'

      def copy_initializer
        template 'calligraphy.rb', 'config/initializers/calligraphy.rb'
      end
    end
  end
end
