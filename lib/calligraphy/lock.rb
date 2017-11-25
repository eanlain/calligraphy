module Calligraphy
  class Lock < WebDavRequest
    include Calligraphy::XML::Utils

    def request
      if @resource.request_body.blank? && !@resource.locked_to_user?(@headers)
        lock_properties = @resource.refresh_lock
      elsif (@resource.locked? && @resource.lock_is_exclusive?) ||
              (@resource.locked_to_user?(@headers) && !xml_contains_shared_lock?)
        return :locked
      else
        resource_exists_beforehand = @resource.exists?

        xml = xml_for body: body, node: 'lockinfo'
        return :bad_request if xml == :bad_request

        lock_properties = @resource.lock xml, @headers['Depth']
      end

      builder = xml_builder
      xml_res = builder.lock_res lock_properties

      lock_token = lock_properties[-1]
        .select { |x| x.name == 'locktoken' }[0]
        .children[0]
        .text

      response.headers['Lock-Token'] = "<#{lock_token}>"
      set_xml_content_type

      if resource_exists_beforehand
        return :ok, xml_res
      else
        return :created, xml_res
      end
    end

    private

    def xml_contains_shared_lock?
      lock_type = nil
      xml = xml_for body: body, node: 'lockinfo'
      xml.each do |node|
        next unless node.is_a? Nokogiri::XML::Element

        lock_type = node.children[0].name if node.name == 'lockscope'
      end

      lock_type == 'shared'
    end
  end
end
