# frozen_string_literal: false

module Support
  module Examples
    module ExtMkcol
      # RFC5689: 3.4. Successful Extended MKCOL Request
      def self.rfc5689_3_4
        <<~XML
          <?xml version="1.0" encoding="utf-8" ?>
          <D:mkcol xmlns:D="DAV:"
                        xmlns:E="http://example.com/ns/">
            <D:set>
              <D:prop>
                <D:resourcetype>
                  <D:collection/>
                  <E:special-resource/>
                </D:resourcetype>
                <D:displayname>Special Resource</D:displayname>
              </D:prop>
            </D:set>
          </D:mkcol>
XML
      end
    end
  end
end
