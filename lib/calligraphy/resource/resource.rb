module Calligraphy
  class Resource
    attr_accessor :client_nonce, :contents, :updated_at
    attr_reader :full_request_path, :mount_point, :request_body, :request_path, :root_dir

    def initialize(resource: nil, req: nil, mount: nil, root_dir: nil)
      @full_request_path = req&.original_url
      @mount_point = mount || req&.path&.tap { |s| s.slice! resource }
      @request_body = req&.body&.read || ''
      @request_path = mount.nil? ? resource : resource.split(mount)[-1]
    end

    def ancestor_exist?
      raise NotImplementedError
    end

    def can_copy?(options)
      raise NotImplementedError
    end

    def collection?
      raise NotImplementedError
    end

    def copy(options)
      raise NotImplementedError
    end

    def create_collection
      raise NotImplementedError
    end

    def dav_compliance
      '1, 2, 3'
    end

    def delete_collection
      raise NotImplementedError
    end

    def etag
      raise NotImplementedError
    end

    def exists?
      raise NotImplementedError
    end

    def lock(nodes, depth='infinity')
      raise NotImplementedError
    end

    def lock_is_exclusive?
      raise NotImplementedError
    end

    def lock_tokens
      raise NotImplementedError
    end

    def locked?
      raise NotImplementedError
    end

    def locked_to_user?(headers=nil)
      raise NotImplementedError
    end

    def propfind(nodes)
      raise NotImplementedError
    end

    def proppatch(nodes)
      raise NotImplementedError
    end

    def read
      raise NotImplementedError
    end

    def readable?
      exists? && !collection?
    end

    def refresh_lock
      raise NotImplementedError
    end

    def unlock(token)
      raise NotImplementedError
    end

    def write(contents=@request_body.to_s)
      raise NotImplementedError
    end

    private

    def creationdate
      raise NotImplementedError
    end

    def displayname
      raise NotImplementedError
    end

    def getcontentlanguage
      raise NotImplementedError
    end

    def getcontentlength
      raise NotImplementedError
    end

    def getcontenttype
      raise NotImplementedError
    end

    def getetag
      raise NotImplementedError
    end

    def getlastmodified
      raise NotImplementedError
    end

    def lockdiscovery
      raise NotImplementedError
    end

    def resourcetype
      raise NotImplementedError
    end

    def supportedlock
      raise NotImplementedError
    end

    def get_custom_property(prop)
      raise NotImplementedError
    end
 end
end
