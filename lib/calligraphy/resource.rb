module Calligraphy
  class Resource
    attr_accessor :contents, :updated_at
    attr_reader :full_request_path, :mount_point, :request_body, :request_path, :root_dir

    def initialize(resource: nil, req: nil, mount: nil, root_dir: nil)
      @full_request_path = req&.original_url
      @mount_point = mount || req&.path&.tap { |s| s.slice! resource }
      @request_body = req&.body&.read || ''
      @request_path = mount.nil? ? resource : resource.split(mount)[-1]
    end

    def ancestor_exist?
      raise NotImplemented
    end

    def can_copy?(options)
      raise NotImplemented
    end

    def collection?
      raise NotImplemented
    end

    def copy(options)
      raise NotImplemented
    end

    def create_collection
      raise NotImplemented
    end

    def delete_collection
      raise NotImplemented
    end

    def etag
      raise NotImplemented
    end

    def exists?
      raise NotImplemented
    end

    def lock(nodes, depth='infinity')
      raise NotImplemented
    end

    def lock_is_exclusive?
      raise NotImplemented
    end

    def lock_tokens
      raise NotImplemented
    end

    def locked?
      raise NotImplemented
    end

    def locked_to_user?(headers=nil)
      raise NotImplemented
    end

    def propfind(nodes)
      raise NotImplemented
    end

    def proppatch(nodes)
      raise NotImplemented
    end

    def read
      raise NotImplemented
    end

    def readable?
      exists? && !collection?
    end

    def refresh_lock
      raise NotImplemented
    end

    def unlock(token)
      raise NotImplemented
    end

    def write(contents=@request_body.to_s)
      raise NotImplemented
    end
  end
end
