# frozen_string_literal: true

module Calligraphy
  # Responsible for copying a resource then deleting the original source.
  class Move < Copy
    # Executes the WebDAV request for a particular resource.
    def execute
      return :locked if @resource.locked_to_user? @headers

      if @resource.is_true? options[:overwrite]
        previous_resource_existed = overwrite_destination
      end

      status = super
      return status if %i[precondition_failed conflict].include? status

      @resource.delete_collection

      response_status status, previous_resource_existed
    end

    private

    def options
      copy_move_options
    end

    def overwrite_destination
      to_path = options[:destination].tap { |s| s.slice! @resource.mount_point }
      to_resource = destination_resource to_path

      if to_resource.exists?
        to_resource.delete_collection
        previous_resource_existed = true
      end

      previous_resource_existed
    end

    def destination_resource(to_path)
      @resource.class.new(
        resource: to_path,
        req: @request,
        root_dir: @resource.root_dir
      )
    end

    def response_status(status, previous_resource)
      return :no_content if status == :created && previous_resource

      response.headers['Location'] = options[:destination] if status == :created

      status
    end
  end
end
