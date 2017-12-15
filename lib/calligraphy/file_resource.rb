require 'pstore'

module Calligraphy
  class FileResource < Resource
    include Calligraphy::Utils

    def initialize(resource: nil, req: nil, mount: nil, root_dir: Dir.pwd)
      super

      @root_dir = root_dir || Dir.pwd
      @src_path = join_paths @root_dir, @request_path

      if exists?
        @name = File.basename @src_path
        init_pstore
        set_file_stats
      end

      set_ancestors
    end

    def ancestor_exist?
      File.exist? @ancestor_path
    end

    def can_copy?(options)
      copy_options = { can_copy: false, ancestor_exist: false, locked: false }

      overwrite = is_true? options[:overwrite]
      destination = options[:destination].tap { |s| s.slice! @mount_point }
      copy_options[:ancestor_exist] = File.exist? parent_path(destination)

      to_path = join_paths @root_dir, destination
      to_path_exist = File.exist? to_path

      copy_options[:locked] = if to_path_exist
        if destination_locked? to_path
          true
        else
          to_path_parent = split_and_pop(path: to_path).join '/'
          common_ancestor = common_path_ancestors(to_path, @ancestors).first
          to_path_ancestors = ancestors_from_path_to_ancestor to_path, common_ancestor

          locking_ancestor? to_path_parent, to_path_ancestors
        end
      else
        false
      end

      if copy_options[:ancestor_exist]
        if !overwrite && to_path_exist
          copy_options[:can_copy] = false
        else
          copy_options[:can_copy] = true
        end
      end

      copy_options
    end

    def collection?
      File.directory? @src_path
    end

    def copy(options)
      destination = options[:destination].tap { |s| s.slice! @mount_point }
      preserve_existing = is_false? options[:overwrite]

      to_path = join_paths @root_dir, destination
      to_path_exists = File.exist? to_path

      if collection?
        FileUtils.cp_r @src_path, to_path, preserve: preserve_existing
      else
        FileUtils.cp @src_path, to_path, preserve: preserve_existing
      end

      if store_exist? && preserve_existing
        dest_store_path = collection? ? "#{to_path}/#{@name}" : to_path
        dest_store_path += ".pstore"

        FileUtils.cp @store_path, dest_store_path, preserve: preserve_existing
      end

      to_path_exists
    end

    def create_collection
      Dir.mkdir @src_path
    end

    def delete_collection
      FileUtils.rm_r @src_path
      FileUtils.rm_r @store_path if store_exist?
    end

    def etag
      [@updated_at.to_i, @stats[:inode], @stats[:size]].join('-').to_s
    end

    def exists?
      File.exist? @src_path
    end

    def lock(nodes, depth='infinity')
      properties = {}

      nodes.each do |node|
        next unless node.is_a? Nokogiri::XML::Element
        properties[node.name.to_sym] = node
      end

      unless exists?
        write ''
        @name = File.basename @src_path
        init_pstore
      end

      create_lock properties, depth
    end

    def lock_is_exclusive?
      lockscope == 'exclusive'
    end

    def lock_tokens
      get_lock_info
      @lock_info&.each { |x| x }&.map { |k, v| k[:locktoken].children[0].text }
    end

    def locked?
      get_lock_info
      obj_exists_and_is_not_type? obj: @lock_info, type: []
    end

    def locked_to_user?(headers=nil)
      if locked?
        !can_unlock? headers
      else
        locking_ancestor? @ancestor_path, @ancestors.dup, headers
      end
    end

    def propfind(nodes)
      properties = { found: [], not_found: [] }

      nodes.each do |node|
        node.children.each do |prop|
          next unless prop.is_a? Nokogiri::XML::Element

          value = get_property prop

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
      end

      properties
    end

    def proppatch(nodes)
      actions = { set: [], remove: [] }

      @store.transaction do
        @store[:properties] = {} unless @store[:properties].is_a? Hash

        nodes.each do |node|
          if node.name == 'set'
            node.children.each do |prop|
              prop.children.each do |property|
                prop_sym = property.name.to_sym
                node = Calligraphy::XML::Node.new property

                if @store[:properties][prop_sym]
                  if @store[:properties][prop_sym].is_a? Array
                    unless matching_namespace? @store[:properties][prop_sym], node
                      @store[:properties][prop_sym].push node
                    end
                  else
                    if !same_namespace? @store[:properties][prop_sym], node
                      @store[:properties][prop_sym] = [@store[:properties][prop_sym]]
                      @store[:properties][prop_sym].push node
                    else
                      @store[:properties][prop_sym] = node
                    end
                  end
                else
                  @store[:properties][prop_sym] = node
                end

                actions[:set].push property
              end
            end
          elsif node.name == 'remove'
            node.children.each do |prop|
              prop.children.each do |property|
                @store[:properties].delete property.name.to_sym

                actions[:remove].push property
              end
            end
          end
        end
      end

      get_custom_property nil
      actions
    end

    def read
      @contents ||= File.read @src_path if readable?
    end

    def refresh_lock
      if locked?
        @store.transaction do
          @store[:lockdiscovery][-1][:timeout] = timeout_node
        end

        get_lock_info
      else
        refresh_ancestor_locks @ancestor_path, @ancestors.dup
      end
    end

    def unlock(token)
      if lock_tokens.include? token
        remove_lock token
        :no_content
      else
        :forbidden
      end
    end

    def write(contents=@request_body.to_s)
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
        size: file_stats.size,
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

      until path.last == stop_at_ancestor
        ancestors.push path.pop
      end

      ancestors.push stop_at_ancestor
      ancestors.reverse
    end

    def store_exist?
      File.exist? @store_path
    end

    def create_lock(properties, depth)
      @store.transaction do
        @store[:lockcreator] = client_nonce
        @store[:lockdiscovery] = [] unless @store[:lockdiscovery].is_a? Array
        @store[:lockdepth] = depth

        activelock = {}
        activelock[:locktoken] = create_lock_token
        activelock[:timeout] = timeout_node

        properties.each_key do |prop|
          activelock[prop] = Calligraphy::XML::Node.new properties[prop]
        end

        @store[:lockdiscovery].push activelock
      end

      get_lock_info
    end

    def create_lock_token
      token = Calligraphy::XML::Node.new
      token.name = 'locktoken'

      href = Calligraphy::XML::Node.new
      href.name = 'href'
      href.text = ['urn', 'uuid', SecureRandom.uuid].join ':'

      token.children = [href]
      token
    end

    def timeout_node
      Calligraphy::XML::Node.new.tap do |node|
        node.name = 'timeout'
        node.text = ['Second', Calligraphy.lock_timeout_period].join '-'
      end
    end

    def get_lock_info
      return nil if @store.nil?

      @lock_info = @store.transaction(true) { @store[:lockdiscovery] }
      @lock_info.nil? ? nil : map_array_of_hashes(@lock_info)
    end

    def lockscope
      @lock_info[-1][:lockscope].children[0].name
    end

    def can_unlock?(headers=nil)
      token = unless headers.nil?
        extract_lock_token(headers['If']) if headers['If']
      end

      lock_tokens.include? token
    end

    def locking_ancestor?(ancestor_path, ancestors, headers=nil)
      ancestor_store_path = "#{ancestor_path}/#{ancestors[-1]}.pstore"
      check_lock_creator = Calligraphy.enable_digest_authentication
      blocking_lock = false
      unlockable = true

      ancestors.pop

      if File.exist? ancestor_store_path
        ancestor_store = PStore.new ancestor_store_path
        ancestor_lock_depth = ancestor_store.transaction(true) do
          ancestor_store[:lockdepth]
        end

        ancestor_lock = ancestor_store.transaction(true) do
          ancestor_store[:lockdiscovery]
        end

        ancestor_lock_creator = ancestor_store.transaction(true) do
          ancestor_store[:lockcreator]
        end if check_lock_creator

        blocking_lock = obj_exists_and_is_not_type? obj: ancestor_lock, type: []

        if blocking_lock
          token = unless headers.nil?
            extract_lock_token(headers['If']) if headers['If']
          end

          ancestor_lock_tokens = ancestor_lock
            .each { |x| x }
            .map { |k, v| k[:locktoken].children[0].text }

          unlockable = ancestor_lock_tokens.include?(token) ||
            (check_lock_creator && (ancestor_lock_creator == client_nonce))
        end
      end

      if blocking_lock || ancestors.empty?
        @locking_ancestor = {
          depth: ancestor_lock_depth,
          info: ancestor_lock
        }

        return unlockable ? false : true
      end

      next_ancestor = split_and_pop(path: ancestor_path).join '/'
      locking_ancestor? next_ancestor, ancestors, headers
    end

    def get_property(prop)
      case prop.name
      when 'creationdate'
        prop.content = @stats[:created_at]
      when 'displayname'
        prop.content = @name
      when 'getcontentlength'
        prop.content = @stats[:size]
      when 'getlastmodified'
        prop.content = @updated_at
      when 'resourcetype'
        prop.content = 'collection'
      when 'lockdiscovery'
        return get_lock_info
      else
        return get_custom_property prop.name
      end

      prop
    end

    def get_custom_property(prop)
      @store_properties ||= @store.transaction(true) { @store[:properties] }
      @store_properties[prop.to_sym] unless @store_properties.nil? || prop.nil?
    end

    def matching_namespace?(node_arr, node)
      node_arr.select { |x| x.namespace.href == node.namespace.href }.length > 0
    end

    def same_namespace?(node1, node2)
      node1.namespace.href == node2.namespace.href
    end

    def refresh_ancestor_locks(ancestor_path, ancestors)
      ancestor_store_path = "#{ancestor_path}/#{ancestors[-1]}.pstore"
      ancestors.pop

      if File.exist? ancestor_store_path
        ancestor_store = PStore.new ancestor_store_path
        ancestor_lock = ancestor_store.transaction(true) do
          ancestor_store[:lockdiscovery][-1][:timeout] = timeout_node
          ancestor_store[:lockdiscovery]
        end

        return map_array_of_hashes ancestor_lock
      end

      next_ancestor = split_and_pop(path: ancestor_path).join '/'
      refresh_ancestor_locks next_ancestor, ancestors
    end

    def remove_lock(token)
      @store.transaction do
        @store.delete :lockcreator

        if @store[:lockdiscovery].length == 1
          @store.delete :lockdiscovery
        else
          @store[:lockdiscovery] = @store[:lockdiscovery].reject do |activelock|
            activelock[:locktoken].children[0].text == token
          end
        end
      end

      @lock_info = nil
    end
  end
end
