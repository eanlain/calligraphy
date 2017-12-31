module ActionDispatch
  module Integration
    module RequestHelpers
      %w[copy move mkcol propfind proppatch lock unlock].each do |method|
        define_method method do |path, **args|
          process method.to_sym, path, **args
        end
      end
    end
  end
end
