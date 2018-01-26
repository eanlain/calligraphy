# frozen_string_literal: true

module Calligraphy
  # Responsible for retrieving properties defined on the resource.
  class Propfind < WebDavRequest
    include Calligraphy::XML::Utils

    # Executes the WebDAV request for a particular resource.
    def execute
      # The `propfind` tag contains the properties to retrieve for a
      # particular resource.
      xml = xml_for body: body, node: 'propfind'
      return :bad_request if xml == :bad_request

      properties = @resource.propfind xml

      builder = xml_builder
      xml_res = builder.propfind_response(@resource.full_request_path,
                                          properties)

      set_xml_content_type

      [:multi_status, xml_res]
    end
  end
end
