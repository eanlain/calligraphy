# frozen_string_literal: false

module Support
  module Examples
    module Acl
      # RFC3744: 8.1.2 The ACL method
      def self.rfc3744_8_1_2
        <<~XML
          <?xml version="1.0" encoding="utf-8" ?>
          <D:acl xmlns:D="DAV:">
            <D:ace>
              <D:principal>
                <D:href>http://www.example.com/users/esedlar</D:href>
              </D:principal>
              <D:grant>
                <D:privilege><D:read/></D:privilege>
                <D:privilege><D:write/></D:privilege>
              </D:grant>
            </D:ace>
            <D:ace>
              <D:principal>
                <D:property><D:owner/></D:property>
              </D:principal>
              <D:grant>
                <D:privilege><D:read-acl/></D:privilege>
                <D:privilege><D:write-acl/></D:privilege>
              </D:grant>
            </D:ace>
            <D:ace>
              <D:principal><D:all/></D:principal>
              <D:grant>
                <D:privilege><D:read/></D:privilege>
              </D:grant>
            </D:ace>
          </D:acl>
XML
      end
    end
  end
end
