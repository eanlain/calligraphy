module Calligraphy::XML
  class Node
    attr_accessor :children, :name, :namespace, :text

    def initialize(node=nil)
      unless node.nil?
        @name = node.name
        @text = node.text unless node.text.empty?

        if node.namespace
          @namespace = Calligraphy::XML::Namespace.new node.namespace
        end

        if node.children&.length > 0
          @children = []
          node.children.each do |child|
            @children.push Calligraphy::XML::Node.new child
          end
        end
      end
    end
  end
end
