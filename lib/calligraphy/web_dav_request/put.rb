# frozen_string_literal: true

module Calligraphy
  # Responsible for replacing the `Get` response entity of the resource.
  class Put < WebDavRequest
    # Executes the WebDAV request for a particular resource.
    def execute
      return :locked if @resource.locked_to_user? @headers
      return :method_not_allowed if @resource.collection?

      @resource.write

      [:created, @resource.contents]
    end
  end
end
