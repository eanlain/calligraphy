module Calligraphy
  class Move < Copy
    def request
      return :locked if @resource.locked_to_user? @headers

      options = copy_move_options

      if @resource.is_true? options[:overwrite]
        to_path = options[:destination].tap { |s| s.slice! @resource.mount_point }
        to_resource = @resource.class.new resource: to_path, req: @request

        if to_resource.exists?
          to_resource.delete_collection
          to_resource_existed = true
        end
      end

      copy_status = super
      return copy_status if [:precondition_failed, :conflict].include? copy_status

      @resource.delete_collection

      if copy_status == :created && to_resource_existed
        return :no_content
      else
        response.headers['Location'] = options[:destination] if copy_status == :created
        return copy_status
      end
    end
  end
end
