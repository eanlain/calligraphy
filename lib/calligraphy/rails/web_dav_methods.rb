# frozen_string_literal: true

module Calligraphy
  module Rails
    # Provides methods to direct the execution of WebDAV actions.
    module WebDavMethods
      private

      def web_dav_request
        {
          headers: request.headers,
          request: request,
          resource: @resource,
          response: response
        }
      end

      def options
        response.headers['DAV'] = @resource.dav_compliance

        :ok
      end

      def get(head: false)
        fresh_when(@resource, etag: @resource.etag) if @resource.readable?

        Calligraphy::Get.new(web_dav_request).execute(head: head)
      end

      def put
        Calligraphy::Put.new(web_dav_request).execute
      end

      def delete
        Calligraphy::Delete.new(web_dav_request).execute
      end

      def copy
        Calligraphy::Copy.new(web_dav_request).execute
      end

      def move
        Calligraphy::Move.new(web_dav_request).execute
      end

      def mkcol
        Calligraphy::Mkcol.new(web_dav_request).execute
      end

      def propfind
        Calligraphy::Propfind.new(web_dav_request).execute
      end

      def proppatch
        Calligraphy::Proppatch.new(web_dav_request).execute
      end

      def lock
        Calligraphy::Lock.new(web_dav_request).execute
      end

      def unlock
        Calligraphy::Unlock.new(web_dav_request).execute
      end
    end
  end
end
