# frozen_string_literal: true

module Calligraphy
  module AclUtils
    def parse_acl(xml)
      [].tap do |ace|
        xml.each do |node|
          next unless node.is_a? Nokogiri::XML::Element

          ace << node
        end
      end
    end
  end
end
