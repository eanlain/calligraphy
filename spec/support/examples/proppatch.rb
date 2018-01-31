# frozen_string_literal: false

module Support
  module Examples
    module Proppatch
      # RFC4918: 9.2.2
      def self.rfc4918_9_2_2
        <<~XML
          <?xml version="1.0" encoding="utf-8" ?>
          <D:propertyupdate xmlns:D="DAV:"
                xmlns:Z="http://ns.example.com/standards/z39.50/">
            <D:set>
              <D:prop>
                <Z:Authors>
                  <Z:Author>Jim Whitehead</Z:Author>
                  <Z:Author>Roy Fielding</Z:Author>
                </Z:Authors>
              </D:prop>
            </D:set>
            <D:remove>
              <D:prop><Z:Copyright-Owner/></D:prop>
            </D:remove>
          </D:propertyupdate>
XML
      end
    end
  end
end
