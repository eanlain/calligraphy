# frozen_string_literal: true

require 'rails/generators/base'

module Calligraphy
  module Generators
    # Generator used to copy Calligraphy initializer over to your application.
    class InstallGenerator < ::Rails::Generators::Base
      source_root File.expand_path('../../templates', __FILE__)

      desc 'Creates a Calligraphy initializer for your application'

      #:nodoc:
      def copy_initializer
        template 'calligraphy.rb', 'config/initializers/calligraphy.rb'
      end
    end
  end
end
