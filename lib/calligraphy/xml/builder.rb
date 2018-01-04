# frozen_string_literal: true

module Calligraphy
  module XML
    # Responsible for building XML responses for WebDAV requests.
    class Builder
      include Calligraphy::XML::WebDavElements

      attr_reader :dav_ns, :default_ns, :server_protocol

      #:nodoc:
      def initialize(dav_ns: 'D', server_protocol: 'HTTP/1.1')
        @dav_ns = dav_ns
        @default_ns = { "xmlns:#{@dav_ns}" => 'DAV:' }
        @server_protocol = server_protocol
      end

      private

      def build(tag)
        Nokogiri::XML::Builder.new do |xml|
          xml[@dav_ns].send(tag, @default_ns) { yield xml }
        end.to_xml
      end

      def multistatus
        build :multistatus do |xml|
          xml.response { yield xml }
        end
      end

      def property_drilldown(xml, property)
        if property.is_a? Array
          iterate_and_drilldown xml, property
        elsif DAV_NS_TAGS.include? property.name
          supported_ns_tag xml, property
        elsif property.namespace&.href
          non_supported_ns_tag xml, property
        else
          nil_ns_tag xml, property
        end
      end

      def iterate_and_drilldown(xml, property_set)
        property_set.each do |property|
          property_drilldown xml, property
        end
      end

      def supported_ns_tag(xml, property)
        if DAV_NS_METHODS.include? property.name
          return send property.name, xml, property
        end

        xml[@dav_ns].send property.name do
          if property.children
            iterate_and_drilldown xml, property.children
          else
            xml.text property.text
          end
        end
      end

      def non_supported_ns_tag(xml, property)
        xml.send property.name, xmlns: property.namespace.href do
          if property.children
            iterate_and_drilldown xml, property.children
          else
            xml.text property.text
          end
        end
      end

      def nil_ns_tag(xml, property)
        xml.send property.name, property.text do
          xml.parent.namespace = nil
        end
      end

      def self_closing_tag(xml, text)
        xml.send text
      end

      def href(xml, path)
        xml[@dav_ns].href path
      end

      def prop(xml, property_set)
        xml[@dav_ns].prop { iterate_and_drilldown xml, property_set }
      end

      def propstat(xml, property_set, status, error_tag: nil, description: nil)
        return if property_set.empty?

        xml[@dav_ns].propstat do
          prop xml, property_set
          status xml, status
          error xml, error_tag unless error_tag.nil?
          responsedescription xml, description unless description.nil?
        end
      end

      def status(xml, status)
        xml[@dav_ns].status status_message status
      end

      def status_message(status)
        status_code = Rack::Utils.status_code status

        [
          @server_protocol,
          status_code,
          Rack::Utils::HTTP_STATUS_CODES[status_code]
        ].join ' '
      end

      def error(xml, error)
        xml.error { self_closing_tag xml, error }
      end

      def responsedescription(xml, description)
        xml.responsedescription do
          xml.text description
        end
      end
    end
  end
end
