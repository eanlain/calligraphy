# frozen_string_literal: true

module Calligraphy
  module XML
    # Simple XML node, used to store resource properties in Resource methods
    # and later to create XML response bodies.
    class Node
      attr_accessor :children, :name, :namespace, :text

      #:nodoc:
      def initialize(node = nil)
        return if node.nil?

        @name = node.name
        @text = node.text unless node.text.empty?

        if node.namespace
          @namespace = Calligraphy::XML::Namespace.new node.namespace
        end

        return unless node_has_children node

        @children = []
        node.children.each { |x| @children.push Calligraphy::XML::Node.new x }
      end

      private

      def node_has_children(node)
        return false if node.children.nil?

        node.children.length.positive?
      end
    end
  end
end
