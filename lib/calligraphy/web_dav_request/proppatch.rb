# frozen_string_literal: true

module Calligraphy
  # Responsible for processing instructions specified in the request body
  # to set and/or remove properties defined on the resource.
  class Proppatch < WebDavRequest
    include Calligraphy::XML::Utils

    # Executes the WebDAV request for a particular resource.
    def execute
      return :locked if @resource.locked_to_user? @headers

      # The `propertyupdate` tag contains the request to alter properties
      # on a resource.
      xml = xml_for body: body, node: 'propertyupdate'
      return :bad_request if xml == :bad_request

      actions = @resource.proppatch xml

      builder = xml_builder
      xml_res = builder.proppatch_response(@resource.full_request_path,
                                           actions)

      set_xml_content_type

      [:multi_status, xml_res]
    end
  end
end
