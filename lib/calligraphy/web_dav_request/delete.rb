module Calligraphy
  class Delete < WebDavRequest
    def request
      return :locked if @resource.locked_to_user? @headers

      if @resource.collection?
        @resource.delete_collection

        return :no_content
      else
        return :not_found unless @resource.exists?
      end

      return :no_content
    end
  end
end
