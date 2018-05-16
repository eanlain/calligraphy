# frozen_string_literal: true

module ActionDispatch
  module Routing
    class Mapper
      #:nodoc:
      module HttpHelpers
        # Define a Calligraphy route that only recognizes HTTP ACL.
        #   acl 'bacon', to: 'food#bacon'
        def acl(*args, &block)
          args = web_dav_args args
          map_method :acl, args, &block
        end

        # Define a Calligraphy route that only recognizes HTTP COPY.
        #   copy 'bacon', to: 'food#bacon'
        def copy(*args, &block)
          args = web_dav_args args
          map_method :copy, args, &block
        end

        # Define a Calligraphy route that only recognizes HTTP HEAD.
        #   head 'bacon', to: 'food#bacon'
        def head(*args, &block)
          args = web_dav_args args
          map_method :head, args, &block
        end

        # Define a Calligraphy route that only recognizes HTTP LOCK.
        #   lock 'bacon', to: 'food#bacon'
        def lock(*args, &block)
          args = web_dav_args args
          map_method :lock, args, &block
        end

        # Define a Calligraphy route that only recognizes HTTP MKCOL.
        #   mkcol 'bacon', to: 'food#bacon'
        def mkcol(*args, &block)
          args = web_dav_args args
          map_method :mkcol, args, &block
        end

        # Define a Calligraphy route that only recognizes HTTP MOVE.
        #   move 'bacon', to: 'food#bacon'
        def move(*args, &block)
          args = web_dav_args args
          map_method :move, args, &block
        end

        # Define a Calligraphy route that only recognizes HTTP OPTIONS.
        #   options 'bacon', to: 'food#bacon'
        def options(*args, &block)
          args = web_dav_args args
          map_method :options, args, &block
        end

        # Define a Calligraphy route that only recognizes HTTP PROPFIND.
        #   propfind 'bacon', to: 'food#bacon'
        def propfind(*args, &block)
          args = web_dav_args args
          map_method :propfind, args, &block
        end

        # Define a Calligraphy route that only recognizes HTTP PROPPATCH.
        #   proppatch 'bacon', to: 'food#bacon'
        def proppatch(*args, &block)
          args = web_dav_args args
          map_method :proppatch, args, &block
        end

        # Define a Calligraphy route that only recognizes HTTP UNLOCK.
        #   unlock 'bacon', to: 'food#bacon'
        def unlock(*args, &block)
          args = web_dav_args args
          map_method :unlock, args, &block
        end

        # Define a Calligraphy route that only recognizes HTTP DELETE.
        #   web_dav_delete 'broccoli', to: 'food#broccoli'
        def web_dav_delete(*args, &block)
          args = web_dav_args args
          map_method :delete, args, &block
        end

        # Define a Calligraphy route that only recognizes HTTP GET.
        #   web_dav_get 'bacon', to: 'food#bacon'
        def web_dav_get(*args, &block)
          args = web_dav_args args
          map_method :get, args, &block
        end

        # Define a Calligraphy route that only recognizes HTTP PUT.
        #   web_dav_put 'bacon', to: 'food#bacon'
        def web_dav_put(*args, &block)
          args = web_dav_args args
          map_method :put, args, &block
        end

        private

        def web_dav_args(args)
          options = {
            controller: 'calligraphy/rails/web_dav_requests',
            action: 'invoke_method'
          }
          [args[0], options]
        end
      end

      #:nodoc:
      module Resources
        #:nodoc:
        class Resource
          # Returns the available WebDAV HTTP verbs based on Calligraphy
          # configuration and Rails routing options.
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

        # With Calligraphy, a resourceful route provides mappings between WebDAV
        # HTTP verbs and URLs and WebDAV controller actions. A single entry in
        # the routing file, such as:
        #
        #   calligraphy_resource :photos
        #
        # creates eleven different routes in your application, all mapping to
        # the WebDavRequests controller:
        #
        #     OPTIONS   /photos/*resource
        #     GET       /photos/*resource
        #     PUT       /photos/*resource
        #     DELETE    /photos/*resource
        #     COPY      /photos/*resource
        #     MOVE      /photos/*resource
        #     MKCOL     /photos/*resource
        #     PROPFIND  /photos/*resource
        #     PROPPATCH /photos/*resource
        #     LOCK      /photos/*resource
        #     UNLOCK    /photos/*resource
        #     ACL       /photos/*resource
        def calligraphy_resource(*resources, &block)
          options = resources.extract_options!.dup

          if apply_common_behavior_for :calligraphy_resource, resources, options, &block
            return self
          end

          with_scope_level(:resource) do
            options = apply_action_options options

            resource_scope(SingletonResource.new(resources.pop, api_only?, @scope[:shallow], options)) do
              yield if block_given?

              concerns(options[:concerns]) if options[:concerns]

              set_mappings_for_web_dav_resources
            end
          end
        end

        private

        def set_mappings_for_web_dav_resources
          parent_resource.web_dav_actions.each do |action|
            # Rails already defines GET, PUT, and DELETE actions which we don't
            # want to override. Instead, we map WebDAV GET, PUT, and DELETE
            # HTTP actions to 'web_dav_' prefixed methods.
            if %i[get put delete].include? action
              send "web_dav_#{action}", '*resource'
            else
              send action, '*resource'
            end
          end
        end
      end
    end
  end
end
