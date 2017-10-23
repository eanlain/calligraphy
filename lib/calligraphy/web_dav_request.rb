module Calligraphy
  class WebDavRequest
    attr_accessor :resource, :response
    attr_reader :headers, :request

    def initialize(headers:, request:, response:, resource:)
      @headers = headers
      @request = request
      @response = response
      @resource = resource
    end

    def request
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
      Calligraphy::XML::Builder.new server_protocol: @request.env['SERVER_PROTOCOL']
    end
  end
end
