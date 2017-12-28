# frozen_string_literal: true

module Calligraphy
  module Rails
    # Controller for all WebDAV requests.
    class WebDavRequestsController < ActionController::Base
      include Calligraphy::Rails::WebDavMethods
      include Calligraphy::Rails::WebDavPreconditions

      before_action :verify_resource_scope
      before_action :authenticate_with_digest_authentiation
      before_action :set_resource

      # Entry-point for all WebDAV requests. Handles checking and validating
      # preconditions, directing of requests to the proper WebDAV action
      # method, and composing responses to send back to the client.
      def invoke_method
        unless check_preconditions
          return send_response(status: :precondition_failed)
        end

        method = request.request_method.downcase
        status, body = make_request method

        send_response status: status, body: body
      end

      private

      def verify_resource_scope
        # Prevent any request with `.` or `..` as part of the resource.
        head :forbidden if %w[. ..].any? do |seg|
          params[:resource].include? seg
        end
      end

      def authenticate_with_digest_authentiation
        return unless digest_enabled?

        realm = Calligraphy.http_authentication_realm

        authenticate_or_request_with_http_digest(realm) do |username|
          Calligraphy.digest_password_procedure.call(username)
        end
      end

      def digest_enabled?
        Calligraphy.enable_digest_authentication
      end

      def set_resource
        @resource_class = params[:resource_class] || Calligraphy::Resource
        @resource_root_path = params[:resource_root_path]

        @resource = @resource_class.new(
          resource: resource_id,
          req: request,
          root_dir: @resource_root_path
        )
      end

      def resource_id
        if params[:format]
          [params[:resource], params[:format]].join '.'
        else
          params[:resource]
        end
      end

      def make_request(method)
        if method == 'head'
          status = get head: true
        elsif Calligraphy.allowed_http_methods.include? method
          resource_client_nonce(method) if digest_enabled?

          status, body = send method
        else
          status = :method_not_allowed
        end

        [status, body]
      end

      def resource_client_nonce(_method)
        @resource.client_nonce = client_nonce
      end

      def client_nonce
        auth_header = request.headers['HTTP_AUTHORIZATION']
        digest = ::ActionController::HttpAuthentication::Digest

        auth = digest.decode_credentials auth_header
        auth[:cnonce]
      end

      def send_response(status:, body: nil)
        if body.nil?
          head status
        else
          render body: body, status: status
        end
      end
    end
  end
end
