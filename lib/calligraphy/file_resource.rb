require 'pstore'

module Calligraphy
  class FileResource < Resource
    include Calligraphy::Utils

    def initialize(resource: nil, req: nil, mount: nil)
      super

      @root_dir = Dir.pwd
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

        FileUtils.cp @store_path, "#{dest_store_path}.pstore", preserve: preserve_existing
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
        updated_at: file_stats.mtime,
      }
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

      lock.nil? ? false : lock != {}
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
  end
end
