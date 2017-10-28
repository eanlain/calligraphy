module Calligraphy
  class Proppatch < WebDavRequest
    include Calligraphy::XML::Utils

    def request
      return :locked if @resource.locked_to_user? @headers

      xml = xml_for body: body, node: 'propertyupdate'
      return :bad_request if xml == :bad_request

      actions = @resource.proppatch xml

      builder = xml_builder
      xml_res = builder.proppatch_res @resource.full_request_path, actions

      set_xml_content_type
      return :multi_status, xml_res
    end
  end
end
