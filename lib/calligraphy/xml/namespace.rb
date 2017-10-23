module Calligraphy::XML
  class Namespace
    attr_accessor :href, :prefix

    def initialize(namespace)
      @href = namespace.href if namespace.href
      @prefix = namespace.prefix if namespace.prefix
    end
  end
end
