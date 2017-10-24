module ActionDispatch::Routing
  class Mapper
    module HttpHelpers
      def copy(*args, &block)
        args = set_web_dav_args args
        map_method :copy, args, &block
      end

      def head(*args, &block)
        args = set_web_dav_args args
        map_method :head, args, &block
      end

      def lock(*args, &block)
        args = set_web_dav_args args
        map_method :lock, args, &block
      end

      def mkcol(*args, &block)
        args = set_web_dav_args args
        map_method :mkcol, args, &block
      end

      def move(*args, &block)
        args = set_web_dav_args args
        map_method :move, args, &block
      end

      def options(*args, &block)
        args = set_web_dav_args args
        map_method :options, args, &block
      end

      def propfind(*args, &block)
        args = set_web_dav_args args
        map_method :propfind, args, &block
      end

      def proppatch(*args, &block)
        args = set_web_dav_args args
        map_method :proppatch, args, &block
      end

      def unlock(*args, &block)
        args = set_web_dav_args args
        map_method :unlock, args, &block
      end

      def web_dav_delete(*args, &block)
        args = set_web_dav_args args
        map_method :delete, args, &block
      end

      def web_dav_get(*args, &block)
        args = set_web_dav_args args
        map_method :get, args, &block
      end

      def web_dav_put(*args, &block)
        args = set_web_dav_args args
        map_method :put, args, &block
      end

      private

      def set_web_dav_args(args)
        options = {}
        options[:controller] = 'calligraphy/rails/web_dav_requests'
        options[:action] = 'invoke_method'
        [args[0], options]
      end
    end

    module Resources
      class Resource
        def web_dav_actions
          if @only
            Array(@only).map(&:to_sym)
          elsif @except
            Calligraphy.web_dav_actions - Array(@except).map(&:to_sym)
          else
            Calligraphy.web_dav_actions
          end
        end
      end

      def calligraphy_resource(*resources, &block)
        options = resources.extract_options!.dup

        if apply_common_behavior_for :calligraphy_resource, resources, options, &block
          return self
        end

        with_scope_level(:resource) do
          options = apply_action_options options
          singleton_resoure = ActionDispatch::Routing::Mapper::SingletonResource
          resource_scope(singleton_resoure.new resources.pop, api_only?, @scope[:shallow], options) do
            yield if block_given?

            concerns(options[:concerns]) if options[:concerns]

            set_mappings_for_web_dav_resources
          end
        end
      end

      private

      def set_mappings_for_web_dav_resources
        parent_resource.web_dav_actions.each do |action|
          if [:get, :put, :delete].include? action
            send "web_dav_#{action.to_s}", '*resource'
          else
            send action, '*resource'
          end
        end
      end
    end
  end
end
