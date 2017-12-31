# frozen_string_literal: true

module Calligraphy
  module XML
    # Methods to help build WebDAV elements and properties.
    module WebDavElements
      DAV_NS_TAGS = %w[
        activelock allprop collection creationdate depth displayname error
        exclusive getcontentlanguage getcontentlength getcontenttype getetag
        getlastmodified href include location lockdiscovery lockentry lockinfo
        lockroot lockscope locktoken locktype multistatus owner prop
        propertyupdate propfind propname propstat remove response
        responsedescription resourcetype set shared status supportedlock
        timeout write
      ].freeze

      DAV_NS_METHODS = %w[resourcetype supportedlock timeout].freeze

      # Build an XML response for a LOCK request.
      def lock_response(activelock_properties)
        build :prop do |xml|
          xml.lockdiscovery do
            activelock_properties.each do |properties|
              xml.activelock do
                iterate_and_drilldown xml, properties
              end
            end
          end
        end
      end

      # Build an XML response for a PROPFIND request.
      def propfind_response(path, properties)
        multistatus do |xml|
          href xml, path
          propstat xml, properties[:found], :ok
          propstat xml, properties[:not_found], :not_found
        end
      end

      # Build an XML response for a PROPPATCH request.
      def proppatch_response(path, actions)
        multistatus do |xml|
          href xml, path
          propstat xml, actions[:set]
          propstat xml, actions[:remove]
        end
      end

      private

      def resourcetype(xml, property)
        xml[@dav_ns].resourcetype do
          self_closing_tag xml, property.text if property.text == 'collection'
        end
      end

      def supportedlock(xml, property)
        children = JSON.parse property.text, symbolize_names: true

        xml[@dav_ns].supportedlock do
          children.each do |child|
            xml[@dav_ns].lockentry do
              lockscope xml, child[:lockentry][:lockscope]
              locktype xml, child[:lockentry][:locktype]
            end
          end
        end
      end

      def lockscope(xml, scope)
        xml[@dav_ns].lockscope do
          self_closing_tag xml, scope
        end
      end

      def locktype(xml, type)
        xml[@dav_ns].locktype do
          self_closing_tag xml, type
        end
      end

      # NOTE: `xml[@dav_ns].send timeout` results in Timeout being called, so
      # we have this timeout method for convenience.
      def timeout(xml, property)
        xml[@dav_ns].timeout do
          xml.text property.text
        end
      end
    end
  end
end
