# frozen_string_literal: true

require 'pstore'

module Calligraphy
  # Resource responsible for writing and deleting directories and files to disk.
  class FileResource < Resource
    DAV_PROPERTY_METHODS = %w[
      allprop creationdate displayname getcontentlanguage getcontentlength
      getcontenttype getetag getlastmodified lockdiscovery propname
      resourcetype supportedlock
    ].freeze

    include Calligraphy::Utils
    include Calligraphy::XML::Utils

    #:nodoc:
    def initialize(resource: nil, req: nil, mount: nil, root_dir: Dir.pwd)
      super

      @src_path = join_paths @root_dir, @request_path

      if exists?
        @name = File.basename @src_path
        init_pstore
        set_file_stats
      end

      set_ancestors
    end

    # Responsible for returning a boolean value indicating if an ancestor
    # exists for the resource.
    #
    # Used in COPY and MKCOL requests.
    def ancestor_exist?
      File.exist? @ancestor_path
    end

    # Responsible for returning a boolean value indicating if the resource
    # is a collection.
    #
    # Used in DELETE, MKCOL, MOVE, and PUT requests.
    def collection?
      File.directory? @src_path
    end

    # Responsible for creating a duplicate of the resource in
    # `options[:destination]` (see section 9.8 of RFC4918).
    #
    # Used in COPY and MOVE (which inherits from COPY) requests.
    def copy(options)
      destination = copy_destination options
      to_path = join_paths @root_dir, destination
      to_path_exists = File.exist? to_path

      preserve_existing = false? options[:overwrite]

      copy_resource_to_path to_path, preserve_existing
      copy_pstore_to_path to_path, preserve_existing

      to_path_exists
    end

    # Responsible for returning a hash with keys indicating if the resource
    # can be copied, if an ancestor exists, or if the copy destinatin is
    # locked.
    #
    # Return hash should contain `can_copy`, `ancestor_exist`, and `locked`
    # keys with boolean values.
    #
    # Used in COPY and MOVE (which inherits from COPY) requests.
    def copy_options(options)
      copy_options = { can_copy: false, ancestor_exist: false, locked: false }

      destination = copy_destination options
      to_path = join_paths @root_dir, destination
      to_path_exists = File.exist? to_path

      copy_options[:ancestor_exist] = File.exist? parent_path destination
      copy_options[:locked] = can_copy_locked_option to_path, to_path_exists
      copy_options = can_copy_option copy_options, options, to_path_exists
      copy_options
    end

    # Responsible for creating a new collection based on the resource (see
    # section 9.3 of RFC4918).
    #
    # Used in MKCOL requests.
    def create_collection
      Dir.mkdir @src_path
    end

    # Responsible for deleting a resource collection (see section 9.6 of
    # RFC4918).
    #
    # Used in DELETE and MOVE requests.
    def delete_collection
      FileUtils.rm_r @src_path
      FileUtils.rm_r @store_path if store_exist?
    end

    # Responsible for returning a boolean indicating whether the resource
    # supports Extended MKCOL (see RFC5689).
    def enable_extended_mkcol?
      true
    end

    # Responsible for returning unique identifier used to create an etag.
    #
    # Used in precondition validation, as well as GET, HEAD, and PROPFIND
    # requests.
    def etag
      [@updated_at.to_i, @stats[:inode], @stats[:size]].join('-').to_s
    end

    # Responsible for indicating if the resource already exists.
    #
    # Used in DELETE, LOCK, MKCOL, and MOVE requests.
    def exists?
      File.exist? @src_path
    end

    # Responsible for creating a lock on the resource (see section 9.10 of
    # RFC4918).
    #
    # Used in LOCK requests.
    def lock(nodes, depth = 'infinity')
      properties = {}

      nodes.each do |node|
        next unless node.is_a? Nokogiri::XML::Element

        properties[node.name.to_sym] = node
      end

      create_blank_file unless exists?

      create_lock properties, depth
      fetch_lock_info
    end

    # Responsible for indicating if a resource lock is exclusive.
    #
    # Used in LOCK requests.
    def lock_is_exclusive?
      lockscope == 'exclusive'
    end

    # Responsible for indicating if a resource is current locked.
    #
    # Used in LOCK requests.
    def locked?
      fetch_lock_info

      obj_exists_and_is_not_type? obj: @lock_info, type: []
    end

    # Responsible for indicating if a resource is locked to the current user.
    #
    # Used in DELETE, LOCK, MOVE, PROPPATCH, and PUT requests.
    def locked_to_user?(headers = nil)
      if locked?
        !can_unlock? headers
      else
        locking_ancestor? @ancestor_path, @ancestors.dup, headers
      end
    end

    # Responsible for handling the retrieval of properties defined on the
    # resource (see section 9.1 of RFC4918).
    #
    # Used in PROPFIND requests.
    def propfind(nodes)
      properties = { found: [], not_found: [] }

      find_properties_from_xml_elements nodes, properties

      properties[:found] = properties[:found].uniq.flatten if properties[:found]
      properties
    end

    # Responsible for handling the addition and/or removal of properties
    # defined on the resource through a PROPPATCH request (see section 9.2 of
    # RFC4918).
    #
    # Used in PROPPATCH requests.
    def proppatch(nodes)
      init_pstore unless exists?

      actions = { set: [], remove: [] }

      @store.transaction do
        @store[:properties] = {} unless @store[:properties].is_a? Hash

        add_remove_properties nodes, actions
      end

      get_custom_property nil
      actions
    end

    # Responsible for setting and returning the contents of a resource
    # if it is readable (see section 9.4 of RFC4918).
    #
    # Used in GET requests.
    def read
      @contents ||= File.read @src_path if readable?
    end

    # Responsible for refreshing locks (see section 9.10.2 of RFC4918).
    #
    # Used in LOCK requests.
    def refresh_lock
      if locked?
        @store.transaction do
          @store[:lockdiscovery].last[:timeout] = timeout_node
        end

        fetch_lock_info
      else
        refresh_ancestor_locks @ancestor_path, @ancestors.dup
      end
    end

    # Responsible for unlocking a resource lock (see section 9.11 of RFC4918).
    #
    # Used in UNLOCK requests.
    def unlock(token)
      if lock_tokens.include? token
        remove_lock token
        @lock_info = nil

        :no_content
      else
        :forbidden
      end
    end

    # Responsible for writing contents to a resource (see section 9.7 of
    # RFC4918).
    #
    # Used in PUT requests.
    def write(contents = @request_body.to_s)
      @contents = contents

      File.open(@src_path, 'w') do |file|
        file.write @contents
      end
    end

    private

    def init_pstore
      pstore_path = collection? ? "#{@src_path}/#{@name}" : @src_path
      @store = PStore.new "#{pstore_path}.pstore"
      @store_path = @store.instance_variable_get :@filename
    end

    def set_file_stats
      file_stats = File.stat @src_path

      @stats = {
        created_at: file_stats.ctime,
        inode: file_stats.ino,
        size: file_stats.size
      }
      @updated_at = file_stats.mtime
    end

    def set_ancestors
      @ancestors = split_and_pop path: @request_path
      @ancestor_path = join_paths @root_dir, @ancestors.join('/')
    end

    def parent_path(path)
      join_paths @root_dir, split_and_pop(path: path)
    end

    def copy_destination(options)
      options[:destination].tap { |s| s.slice! @mount_point }
    end

    def can_copy_locked_option(to_path, to_path_exists)
      return false unless to_path_exists
      return true if destination_locked? to_path

      to_path_parent = split_and_pop(path: to_path).join '/'
      common_ancestor = common_path_ancestors(to_path, @ancestors).first
      to_path_ancestors = ancestors_from_path_to_ancestor(to_path,
                                                          common_ancestor)

      locking_ancestor? to_path_parent, to_path_ancestors
    end

    def can_copy_option(copy_options, options, to_path_exists)
      return copy_options unless copy_options[:ancestor_exist]

      copy_options[:can_copy] = if false?(options[:overwrite]) && to_path_exists
                                  false
                                else
                                  true
                                end

      copy_options
    end

    def destination_locked?(path)
      store = PStore.new "#{path}.pstore"
      lock = store.transaction(true) { store[:lockdiscovery] }

      obj_exists_and_is_not_type? obj: lock, type: {}
    end

    def common_path_ancestors(path, ancestors)
      [].tap do |common|
        ancestors.each do |ancestor|
          split_path = path.split ancestor
          common.push ancestor if split_path.length > 1
        end
      end
    end

    def ancestors_from_path_to_ancestor(path, stop_at_ancestor)
      path = split_and_pop path: path
      ancestors = []

      ancestors.push path.pop until path.last == stop_at_ancestor
      ancestors.push stop_at_ancestor
      ancestors.reverse
    end

    def copy_resource_to_path(to_path, preserve_existing)
      if collection?
        FileUtils.cp_r @src_path, to_path, preserve: preserve_existing
      else
        FileUtils.cp @src_path, to_path, preserve: preserve_existing
      end
    end

    def copy_pstore_to_path(to_path, preserve_existing)
      return unless store_exist? && preserve_existing

      dest_store_path = collection? ? "#{to_path}/#{@name}" : to_path
      dest_store_path += '.pstore'

      FileUtils.cp @store_path, dest_store_path, preserve: preserve_existing
    end

    def store_exist?
      File.exist? @store_path
    end

    def create_blank_file
      write ''
      @name = File.basename @src_path
      init_pstore
    end

    def create_lock(properties, depth)
      @store.transaction do
        @store[:lockcreator] = client_nonce
        @store[:lockdepth] = depth
        @store[:lockdiscovery] = [] unless @store[:lockdiscovery].is_a? Array

        @store[:lockdiscovery].push({}.tap do |activelock|
          activelock[:locktoken] = create_lock_token
          activelock[:timeout] = timeout_node

          add_lock_properties activelock, properties
        end)
      end
    end

    def create_lock_token
      href = xml_node 'href'
      href.content = ['urn', 'uuid', SecureRandom.uuid].join ':'

      token = xml_node 'locktoken'
      token.add_child href
      token.serialize
    end

    def timeout_node
      node = xml_node 'timeout'
      node.content = ['Second', Calligraphy.lock_timeout_period].join '-'
      node.serialize
    end

    def add_lock_properties(activelock, properties)
      properties.each_key do |prop|
        activelock[prop] = properties[prop].serialize
      end
    end

    def fetch_lock_info
      return nil if @store.nil?

      @lock_info = @store.transaction(true) do
        @store[:lockdiscovery]&.map do |lock_info|
          lock_info.transform_values do |xml_fragment|
            parse_serialized_fragment xml_fragment
          end
        end
      end

      @lock_info.nil? ? nil : map_array_of_hashes(@lock_info)
    end

    def lockscope
      @lock_info
        .last[:lockscope]
        .children
        .select { |x| x.is_a? Nokogiri::XML::Element }
        .last
        .name
    end

    def can_unlock?(headers = nil)
      token = unless headers.nil?
                extract_lock_token(headers['If']) if headers['If']
              end

      lock_tokens.include? token
    end

    def lock_tokens
      fetch_lock_info

      @lock_info&.each { |x| x }&.map { |x| x[:locktoken].text.strip }
    end

    def locking_ancestor?(ancestor_path, ancestors, headers = nil)
      ancestor_info = ancestor_lock_info headers
      ancestor_store_path = "#{ancestor_path}/#{ancestors.last}.pstore"

      ancestors.pop

      check_for_ancestor ancestor_info, ancestor_store_path

      if ancestor_info[:blocking] || ancestors.empty?
        assign_locking_ancestor ancestor_info

        return ancestor_info[:unlockable] ? false : true
      end

      next_ancestor = split_and_pop(path: ancestor_path).join '/'
      locking_ancestor? next_ancestor, ancestors, ancestor_info[:headers]
    end

    def ancestor_lock_info(headers)
      {
        blocking: false,
        check_creator: Calligraphy.enable_digest_authentication,
        creator: nil,
        depth: nil,
        headers: headers || nil,
        lock: nil,
        unlockable: true
      }
    end

    def check_for_ancestor(ancestor_info, store_path)
      return unless File.exist? store_path
      ancestor_lock_from_store ancestor_info, store_path

      ancestor_info[:blocking] = obj_exists_and_is_not_type?(
        obj: ancestor_info[:lock],
        type: []
      )

      blocking_lock_unlockable? ancestor_info if ancestor_info[:blocking]
    end

    def ancestor_lock_from_store(lock_info, store_path)
      ancestor_store = PStore.new store_path

      ancestor_store.transaction(true) do
        lock_info[:lock] = ancestor_store[:lockdiscovery]
        lock_info[:depth] = ancestor_store[:lockdepth]

        if lock_info[:check_creator]
          lock_info[:creator] = ancestor_store[:lockcreator]
        end
      end
    end

    def blocking_lock_unlockable?(lock_info)
      headers = lock_info[:headers]

      token = unless headers.nil?
                extract_lock_token(headers['If']) if headers['If']
              end

      ancestor_tokens = lock_info[:lock]

      lock_info[:unlockable] =
        ancestor_tokens.include?(token) ||
        (lock_info[:check_creator] && (lock_info[:creator] == client_nonce))
    end

    def find_properties_from_xml_elements(nodes, properties)
      nodes.each do |node|
        next unless node.is_a? Nokogiri::XML::Element

        if node.children.length.positive?
          find_properties_from_property_nodes node, properties
        else
          value = get_property node

          update_found_properties properties, node, value
        end
      end
    end

    def find_properties_from_property_nodes(node, properties)
      node.children.each do |prop|
        next unless prop.is_a? Nokogiri::XML::Element

        value = get_property prop

        update_found_properties properties, prop, value
      end
    end

    def ancestor_lock_tokens(lock_info)
      lock_info[:lock].each { |x| x }.map { |k| k[:locktoken].children[0].text }
    end

    def assign_locking_ancestor(ancestor_info)
      @locking_ancestor = {
        depth: ancestor_info[:depth],
        info: ancestor_info[:lock]
      }
    end

    def get_property(prop)
      case prop.name
      when *DAV_PROPERTY_METHODS
        send prop.name, prop
      else
        get_custom_property prop.name, deserialize: true
      end
    end

    def allprop(_prop)
      get_custom_property nil, deserialize: true

      {}.tap do |properties|
        @store_properties.each_value do |node|
          next unless node.is_a? Nokogiri::XML::Element

          properties[node.name.to_sym] = node
        end

        (DAV_PROPERTY_METHODS - %w[allprop propname]).each do |property|
          properties[property.to_sym] = send property, xml_node(property)
        end
      end
    end

    def creationdate(prop)
      prop.content = @stats[:created_at]
      prop
    end

    def displayname(prop)
      prop.content = get_custom_property(:displayname) || @name
      prop
    end

    def getcontentlanguage(prop)
      prop.content = get_custom_property :contentlanguage
      prop
    end

    def getcontentlength(prop)
      prop.content = @stats[:size]
      prop
    end

    def getcontenttype(prop)
      prop.content = get_custom_property :contenttype
      prop
    end

    def getetag(prop)
      cache_key = ActiveSupport::Cache.expand_cache_key [@resource.etag, '']

      prop.content = "W/\"#{Digest::MD5.hexdigest(cache_key)}\""
      prop
    end

    def getlastmodified(prop)
      prop.content = @updated_at
      prop
    end

    # def include(prop)
    #   # TODO: Implement
    #   prop
    # end

    def lockdiscovery(prop)
      prop.content = fetch_lock_info
      prop
    end

    def propname(_prop)
      get_custom_property nil, deserialize: true

      {}.tap do |properties|
        @store_properties.each_value do |node|
          next unless node.is_a? Nokogiri::XML::Element

          properties[node.name.to_sym] = xml_node node.name
        end
      end
    end

    def resourcetype(prop)
      prop.content = 'collection' if collection?
      prop
    end

    def supportedlock(prop)
      exclusive_write = lockentry_hash('exclusive', 'write')
      shared_write = lockentry_hash('shared', 'write')

      prop.content = JSON.generate [exclusive_write, shared_write]
      prop
    end

    def get_custom_property(prop, deserialize: false)
      @store_properties ||= @store.transaction(true) do
        if deserialize
          deserialize_stored_properties @store[:properties]
        else
          @store[:properties]
        end
      end

      @store_properties[prop.to_sym] unless @store_properties.nil? || prop.nil?
    end

    def update_found_properties(properties, prop, value)
      if value.nil?
        properties[:not_found].push prop
      elsif value.is_a? Hash
        value.each_key do |key|
          properties[:found].push value[key]
        end
      else
        properties[:found].push value
      end
    end

    def add_remove_properties(nodes, actions)
      nodes.each do |node|
        if node.name == 'set'
          add_properties node, actions
        elsif node.name == 'remove'
          remove_properties node, actions
        end
      end
    end

    def add_properties(node, actions)
      node.children.each do |prop|
        prop.children.each do |property|
          next unless property.is_a? Nokogiri::XML::Element

          prop_sym = property.name.to_sym
          store_property_node property.clone.serialize, prop_sym

          actions[:set].push property
        end
      end
    end

    def store_property_node(node, prop)
      # Property does not exist yet so we can just store the property node.
      return @store[:properties][prop] = node unless @store[:properties][prop]

      if @store[:properties][prop].is_a? Array
        store_mismatch_namespace_property_node node, prop
      elsif same_namespace? @store[:properties][prop], node
        # If stored property and node have the same namespace, we can just
        # overwrite the previously stored property node.
        @store[:properties][prop] = node
      else
        # If stored property and node DO NOT have the same namespace, create
        # an array for the stored property and push the new property node.
        store_mismatch_namespace_property_nodes node, prop
      end
    end

    def store_mismatch_namespace_property_node(node, prop)
      node_arr = @store[:properties][prop]

      namespace_mismatch = node_arr.select do |stored_node|
        same_namespace? stored_node, node
      end.length.positive?

      @store[:properties][prop].push node unless namespace_mismatch
    end

    def same_namespace?(node1, node2)
      node1_xml = parse_serialized_fragment node1
      node2_xml = parse_serialized_fragment node2

      node1_xml.namespace&.href == node2_xml.namespace&.href
    end

    def store_mismatch_namespace_property_nodes(node, prop)
      @store[:properties][prop] = [@store[:properties][prop]]
      @store[:properties][prop].push node
    end

    def remove_properties(node, actions)
      node.children.each do |prop|
        prop.children.each do |property|
          @store[:properties].delete property.name.to_sym

          actions[:remove].push property
        end
      end
    end

    def refresh_ancestor_locks(ancestor_path, ancestors)
      ancestor_store_path = "#{ancestor_path}/#{ancestors.last}.pstore"
      ancestors.pop

      if File.exist? ancestor_store_path
        ancestor_lock = refresh_ancestor_lock ancestor_store_path

        return map_array_of_hashes ancestor_lock
      end

      next_ancestor = split_and_pop(path: ancestor_path).join '/'
      refresh_ancestor_locks next_ancestor, ancestors
    end

    def refresh_ancestor_lock(ancestor_store_path)
      ancestor_store = PStore.new ancestor_store_path

      ancestor_store.transaction do
        ancestor_store[:lockdiscovery].last[:timeout] = timeout_node
        ancestor_store[:lockdiscovery]&.map do |lock_info|
          lock_info.transform_values do |xml_fragment|
            parse_serialized_fragment xml_fragment
          end
        end
      end
    end

    def remove_lock(token)
      @store.transaction do
        @store.delete :lockcreator

        if @store[:lockdiscovery].length == 1
          @store.delete :lockdiscovery
        else
          @store[:lockdiscovery] = @store[:lockdiscovery].reject do |activelock|
            activelock[:locktoken].include? token
          end
        end
      end
    end
  end
end
