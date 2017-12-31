# frozen_string_literal: true

module Calligraphy
  # Base class for WebDavRequests.
  #
  # `WebDavRequest` exposes the `request` method, which is used by the
  # `WebDavRequestsController` to execute the WebDAV request for a particular
  # resource. This class also provides private methods for accessing the
  # request body, setting response headers, and creating XML responses.
  class WebDavRequest
    attr_accessor :resource, :response
    attr_reader :headers, :request

    #:nodoc:
    def initialize(headers:, request:, response:, resource:)
      @headers = headers
      @request = request
      @response = response
      @resource = resource
    end

    # Executes the WebDAV request for a particular resource.
    def execute
      raise NotImplemented
    end

    private

    def body
      @resource.request_body
    end

    def set_xml_content_type
      @response.content_type = 'application/xml'
    end

    def xml_builder
      protocol = @request.env['SERVER_PROTOCOL']

      Calligraphy::XML::Builder.new server_protocol: protocol
    end
  end
end
