# frozen_string_literal: true

module Calligraphy
  module XML
    # Miscellaneous XML convenience methods.
    module Utils
      # Returns the XML for a given XML body and node/CSS selector.
      def xml_for(body:, node:)
        xml = Nokogiri::XML body
        return :bad_request unless xml.errors.empty?

        namespace = nil
        xml.root.namespace_definitions.each do |n|
          namespace = "#{n.prefix}|" if dav_namespace n
        end

        node = node.split(' ').map! { |n| namespace + n }.join(' ') if namespace

        xml.css(node).children
      end

      private

      def dav_namespace(namespace)
        namespace&.href == Calligraphy::DAV_NS && !namespace.prefix.nil?
      end
    end
  end
end
