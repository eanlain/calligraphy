# frozen_string_literal: true

module ActionDispatch
  module Integration
    module RequestHelpers
      request_methods = %w[
        copy move mkcol options propfind proppatch lock unlock
      ]

      request_methods.each do |method|
        define_method method do |path, **args|
          process method.to_sym, path, **args
        end
      end
    end
  end
end
