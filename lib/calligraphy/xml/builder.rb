module Calligraphy::XML
  class Builder
    SUPPORTED_NS_TAGS = %w(
      creationdate displayname exclusive getcontentlanguage getcontentlength
      getcontenttype getetag getlastmodified href lockdiscovery lockscope
      locktype owner write
    )

    attr_reader :dav_ns, :default_ns, :server_protocol

    def initialize(dav_ns: 'D', server_protocol: 'HTTP/1.1')
      @dav_ns = dav_ns
      @default_ns = { "xmlns:#{@dav_ns}" => 'DAV:' }
      @server_protocol = server_protocol
    end

    def lock_res(activelock_properties)
      build :prop do |xml|
        xml.lockdiscovery do
          activelock_properties.each do |properties|
            activelock xml, properties
          end
        end
      end
    end

    def propfind_res(path, properties)
      multistatus do |xml|
        href xml, path
        propstat xml, properties[:found], :ok
        propstat xml, properties[:not_found], :not_found
      end
    end

    def proppatch_res(path, actions)
      multistatus do |xml|
        href xml, path
        propstat xml, actions[:set]
        propstat xml, actions[:remove]
      end
    end

    private

    def build(tag)
      Nokogiri::XML::Builder.new do |xml|
        xml[@dav_ns].send(tag, @default_ns) do
          yield xml
        end
      end.to_xml
    end

    def activelock(xml, property_set)
      xml.activelock do
        property_set.each do |property|
          property_drilldown xml, property
        end
      end
    end

    def href(xml, path)
      xml.href path
    end

    def multistatus
      build :multistatus do |xml|
        xml.response do
          yield xml
        end
      end
    end

    def prop(xml, property_set)
      xml.prop do
        property_set.each do |property|
          property_drilldown xml, property
        end
      end
    end

    def propstat(xml, property_set, status=:ok)
      return unless property_set.length > 0

      xml.propstat do
        prop xml, property_set
        status xml, status
      end
    end

    def resourcetype(xml, property)
      if property.children.text == 'collection'
        xml[@dav_ns].resourcetype do
          xml.send 'collection'
        end
      else
        xml[@dav_ns].resourcetype
      end
    end

    def status(xml, status)
      xml.status status_message status
    end

    def supportedlock(xml, property)
      children = JSON.parse property.text, symbolize_names: true

      xml[@dav_ns].supportedlock do
        children.each do |child|
          xml[@dav_ns].lockentry do
            xml[@dav_ns].lockscope do
              xml.text child[:lockentry][:lockscope]
            end

            xml[@dav_ns].locktype do
              xml.text child[:lockentry][:locktype]
            end
          end
        end
      end
    end

    # NOTE: `xml[@dav_ns].send timeout` results in Timeout being called, so
    # we have this timeout method for convenience
    def timeout(xml, property)
      xml[@dav_ns].timeout do
        xml.text property.text
      end
    end

    def property_drilldown(xml, property)
      if property.is_a? Array
        property.each do |prop|
          property_drilldown xml, prop
        end
      elsif property.children && property.text.nil?
        xml.send property.name do
          property.children.each do |child|
            property_drilldown xml, child
          end
        end
      elsif property.name == 'resourcetype'
        resourcetype xml, property
      elsif property.name == 'supportedlock'
        supportedlock xml, property
      elsif property.name == 'timeout'
        timeout xml, property
      elsif SUPPORTED_NS_TAGS.include? property.name
        xml[@dav_ns].send property.name do
          xml.text property.text
        end
      elsif property.namespace && property.namespace.href
        xml.send property.name, xmlns: property.namespace.href do
          xml.text property.text
        end
      else
        xml.send property.name, property.text do
          xml.parent.namespace = nil
        end
      end
    end

    def status_message(status)
      status_code = Rack::Utils.status_code status
      [@server_protocol, status_code, Rack::Utils::HTTP_STATUS_CODES[status_code]].join ' '
    end
  end
end
