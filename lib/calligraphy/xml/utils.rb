# frozen_string_literal: true

module Calligraphy
  module XML
    # Miscellaneous XML convenience methods.
    module Utils
      # Returns the inner XML for a given XML body and node/CSS selector.
      def xml_for(body:, node:)
        xml = Nokogiri::XML body
        return :bad_request unless xml.errors.empty?

        namespace = dav_namespace xml

        xml.css("dav|#{node}", 'dav': namespace).children
      end

      # Searches XML body for a given node/CSS selector and returns that
      # node/CSS selector.
      def search_xml_for(body:, search:)
        xml = Nokogiri::XML body

        [].tap do |results|
          xml.namespaces.each_value do |v|
            results << xml.css("cs|#{search}", 'cs': v)
          end
        end.flatten
      end

      # Parses a serialized string or array fragment to XML.
      def parse_serialized_fragment(fragment)
        xml_str = fragment.is_a?(Array) ? fragment.join : fragment

        xml = Nokogiri::XML.fragment(xml_str).children
        fragment.is_a?(Array) ? xml : xml.last
      end

      # Iterates through each property in `properties` hash and deserializes
      # the property's value.
      def deserialize_stored_properties(properties)
        return if properties.nil?

        properties.each_pair do |k, v|
          properties[k] = parse_serialized_fragment v
        end
      end

      # Iterates through top level nodes, finds node names that match and
      # separates matching nodes from non-matching nodes.
      def separate_nodes_by_name(nodes, match_name)
        { found: [], not_found: [] }.tap do |property|
          nodes.each do |node|
            next unless node.is_a? Nokogiri::XML::Element

            if node.name == match_name
              property[:found].push node
            else
              property[:not_found].push node
            end
          end
        end
      end

      # Creates a new instance of Nokogiri::XML::Node with a given name.
      def xml_node(name)
        Nokogiri::XML::Node.new name, dummy_doc
      end

      private

      def dav_namespace(xml)
        xml.namespaces.each_value do |v|
          return v if v == Calligraphy::DAV_NS
        end
      end

      def dummy_doc
        Nokogiri::XML::Document.new
      end
    end
  end
end
