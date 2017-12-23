module Calligraphy
  class Propfind < WebDavRequest
    include Calligraphy::XML::Utils

    def request
      xml = xml_for body: body, node: 'propfind'
      return :bad_request if xml == :bad_request

      properties = @resource.propfind xml

      builder = xml_builder
      xml_res = builder.propfind_res @resource.full_request_path, properties

      set_xml_content_type
      return :multi_status, xml_res
    end
  end
end
