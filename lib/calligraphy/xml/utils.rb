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

      # Iterates through top level nodes, finds node names that match and
      # separates matching nodes from non-matching nodes.
      def separate_nodes_by_name(nodes, match_name)
        { found: [], not_found: [] }.tap do |property|
          nodes.each do |node|
            next unless node.is_a? Nokogiri::XML::Element

            if node.name == match_name
              property[:found].push Calligraphy::XML::Node.new node
            else
              property[:not_found].push Calligraphy::XML::Node.new node
            end
          end
        end
      end

      private

      def dav_namespace(xml)
        xml.namespaces.each_value do |v|
          return v if v == Calligraphy::DAV_NS
        end
      end
    end
  end
end
