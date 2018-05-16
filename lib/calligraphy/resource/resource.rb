# frozen_string_literal: true

module Calligraphy
  # Resource base class.
  #
  # All custom resource classes should be inherited from Resource and should
  # implement the relevant methods needed for the desired level of WebDAV
  # support.
  class Resource
    attr_accessor :client_nonce, :contents, :updated_at
    attr_reader :full_request_path, :mount_point, :request_body, :request_path,
                :root_dir

    #:nodoc:
    def initialize(resource: nil, req: nil, mount: nil, root_dir: nil)
      @full_request_path = req&.original_url
      @mount_point = mount || req&.path&.tap { |s| s.slice! resource }
      @request_body = req&.body&.read || ''
      @request_path = mount.nil? ? resource : resource.split(mount).last
      @root_dir = root_dir
    end

    # Responsible for returning a boolean value indicating if an ancestor
    # exists for the resource.
    #
    # Used in COPY and MKCOL requests.
    def ancestor_exist?
      raise NotImplementedError
    end

    # Responsible for returning a boolean value indicating if the resource
    # is a collection.
    #
    # Used in DELETE, MKCOL, MOVE, and PUT requests.
    def collection?
      raise NotImplementedError
    end

    # Responsible for creating a duplicate of the resource in
    # `options[:destination]` (see section 9.8 of RFC4918).
    #
    # Used in COPY and MOVE (which inherits from COPY) requests.
    def copy(_options)
      raise NotImplementedError
    end

    # Responsible for returning a hash with keys indicating if the resource
    # can be copied, if an ancestor exists, or if the copy destinatin is
    # locked.
    #
    # Return hash should contain `can_copy`, `ancestor_exist`, and `locked`
    # keys with boolean values.
    #
    # Used in COPY and MOVE (which inherits from COPY) requests.
    def copy_options(_options)
      raise NotImplementedError
    end

    # Responsible for creating a new collection based on the resource (see
    # section 9.3 of RFC4918).
    #
    # Used in MKCOL requests.
    def create_collection
      raise NotImplementedError
    end

    # A DAV-compliant resource can advertise several classes of compliance.
    # `dav_compliance` is responsible for returning the classes of WebDAV
    # compliance that the resource supports (see section 18 of RFC4918).
    #
    # Used in OPTIONS requests.
    def dav_compliance
      compliance_classes = %w[1 2 3]
      compliance_classes.push 'access-control' if enable_access_control?
      compliance_classes.push 'extended-mkcol' if enable_extended_mkcol?

      compliance_classes.join ', '
    end

    # Responsible for deleting a resource collection (see section 9.6 of
    # RFC4918).
    #
    # Used in DELETE and MOVE requests.
    def delete_collection
      raise NotImplementedError
    end

    # Responsible for returning a boolean indicating whether the resource
    # supports Access Control Protocol (see RFC3744).
    def enable_access_control?
      false
    end

    # Responsible for returning a boolean indicating whether the resource
    # supports Extended MKCOL (see RFC5689).
    def enable_extended_mkcol?
      false
    end

    # Responsible for returning unique identifier used to create an etag.
    #
    # Used in precondition validation, as well as GET, HEAD, and PROPFIND
    # requests.
    def etag
      raise NotImplementedError
    end

    # Responsible for indicating if the resource already exists.
    #
    # Used in DELETE, LOCK, MKCOL, and MOVE requests.
    def exists?
      raise NotImplementedError
    end

    # Responsible for creating a lock on the resource (see section 9.10 of
    # RFC4918).
    #
    # Used in LOCK requests.
    def lock(_nodes, _depth = 'infinity')
      raise NotImplementedError
    end

    # Responsible for indicating if a resource lock is exclusive.
    #
    # Used in LOCK requests.
    def lock_is_exclusive?
      raise NotImplementedError
    end

    # Responsible for indicating if a resource is current locked.
    #
    # Used in LOCK requests.
    def locked?
      raise NotImplementedError
    end

    # Responsible for indicating if a resource is locked to the current user.
    #
    # Used in DELETE, LOCK, MOVE, PROPPATCH, and PUT requests.
    def locked_to_user?(_headers = nil)
      raise NotImplementedError
    end

    # Responsible for handling the retrieval of properties defined on the
    # resource (see section 9.1 of RFC4918).
    #
    # Used in PROPFIND requests.
    def propfind(_nodes)
      raise NotImplementedError
    end

    # Responsible for handling the addition and/or removal of properties
    # defined on the resource through a PROPPATCH request (see section 9.2 of
    # RFC4918).
    #
    # Used in PROPPATCH requests.
    def proppatch(_nodes)
      raise NotImplementedError
    end

    # Responsible for setting and returning the contents of a resource
    # if it is readable (see section 9.4 of RFC4918).
    #
    # Used in GET requests.
    def read
      raise NotImplementedError
    end

    # Responsible for indicating if a resource is readable.
    #
    # Used in GET and HEAD requests.
    def readable?
      exists? && !collection?
    end

    # Responsible for refreshing locks (see section 9.10.2 of RFC4918).
    #
    # Used in LOCK requests.
    def refresh_lock
      raise NotImplementedError
    end

    # Responsible for unlocking a resource lock (see section 9.11 of RFC4918).
    #
    # Used in UNLOCK requests.
    def unlock(_token)
      raise NotImplementedError
    end

    # Responsible for writing contents to a resource (see section 9.7 of
    # RFC4918).
    #
    # Used in PUT requests.
    def write(_contents = @request_body.to_s)
      raise NotImplementedError
    end

    # Responsible for declaring the valid `resourcetypes` for a resource. If
    # an extended MKCOL request is made using an invalid `resourcetype` the
    # request will fail with a 403 (Forbidden) and will return an XML response
    # with the `mkcol-response` element (see section 3.3 and 3.5 of RFC5689).
    #
    # Used in Extended MKCOL requests.
    def valid_resourcetypes
      %w[collection]
    end

    private

    # DAV property which can be retrieved by a PROPFIND request. `creationdate`
    # records the time and date the resource was created (see section 15.1 of
    # RFC4918).
    def creationdate
      raise NotImplementedError
    end

    # DAV property which can be retrieved by a PROPFIND request. `displayname`
    # returns a name for the resource that is suitable for presentation to the
    # user (see section 15.2 of RFC4918).
    def displayname
      raise NotImplementedError
    end

    # DAV property which can be retrieved by a PROPFIND request.
    # `getcontentlanguage` returns the Content-Language header value (see
    # section 15.3 of RFC4918).
    def getcontentlanguage
      raise NotImplementedError
    end

    # DAV property which can be retrieved by a PROPFIND request.
    # `getcontentlength` returns the Content-Length header value (see section
    # 15.4 of RFC4918).
    def getcontentlength
      raise NotImplementedError
    end

    # DAV property which can be retrieved by a PROPFIND request.
    # `getcontenttype` returns the Content-Type header value (see section
    # 15.5 of RFC4918).
    def getcontenttype
      raise NotImplementedError
    end

    # DAV property which can be retrieved by a PROPFIND request.
    # `getetag` returns the ETag header value (see section 15.6 of RFC4918).
    def getetag
      raise NotImplementedError
    end

    # DAV property which can be retrieved by a PROPFIND request.
    # `getlastmodified` returns the Last-Modified header value (see section
    # 15.7 of RFC4918).
    def getlastmodified
      raise NotImplementedError
    end

    # DAV property which can be retrieved by a PROPFIND request.
    # `lockdiscovery` describes the active locks on a resource (see section
    # 15.8 of RFC4918).
    def lockdiscovery
      raise NotImplementedError
    end

    # DAV property which can be retrieved by a PROPFIND request.
    # `resourcetype` specifies the nature of the resource (see section 15.9 of
    # RFC4918).
    def resourcetype
      raise NotImplementedError
    end

    # DAV property which can be retrieved by a PROPFIND request.
    # `supportedlock` provides a listing of the lock capabilities supported by
    # the resource (see section 15.10 of RFC4918).
    def supportedlock
      raise NotImplementedError
    end
  end
end
