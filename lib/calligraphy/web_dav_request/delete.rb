# frozen_string_literal: true

module Calligraphy
  # Responsible for deleting the resource identified by the request.
  class Delete < WebDavRequest
    # Executes the WebDAV request for a particular resource.
    def execute
      return :locked if @resource.locked_to_user? @headers

      if @resource.collection?
        @resource.delete_collection

        return :no_content
      else
        return :not_found unless @resource.exists?
      end

      :no_content
    end
  end
end
