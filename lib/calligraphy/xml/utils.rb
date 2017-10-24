module Calligraphy::XML
  module Utils
    def xml_for(body:, node:)
      xml = Nokogiri::XML body
      return :bad_request unless xml.errors.empty?

      namespace = nil
      xml.root.namespace_definitions.each do |n|
        namespace = "#{n.prefix}|" if n&.href == Calligraphy::DAV_NS && !n.prefix.nil?
      end
      namespace

      node = node.split(' ').map! { |n| namespace + n }.join(' ') if namespace

      xml.css(node).children
    end
  end
end
