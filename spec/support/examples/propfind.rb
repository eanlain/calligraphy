# frozen_string_literal: false

module Support
  module Examples
    module Propfind
      def self.allprop
        <<~XML
          <?xml version="1.0" encoding="utf-8" ?>
          <D:propfind xmlns:D="DAV:">
            <D:allprop/>
          </D:propfind>
XML
      end

      def self.propname
        <<~XML
          <?xml version="1.0" encoding="utf-8" ?>
          <D:propfind xmlns:D="DAV:">
            <D:propname/>
          </D:propfind>
XML
      end
    end
  end
end
