# frozen_string_literal: true

module Calligraphy
  module XML
    # Simple XML namespace, used to store a namespace's href and prefix values.
    class Namespace
      attr_accessor :href, :prefix

      #:nodoc:
      def initialize(namespace)
        @href = namespace.href if namespace.href
        @prefix = namespace.prefix if namespace.prefix
      end
    end
  end
end
