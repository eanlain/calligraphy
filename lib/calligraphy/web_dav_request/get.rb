# frozen_string_literal: true

module Calligraphy
  # Responsible for retrieving whatever information is identified by the
  # request.
  class Get < WebDavRequest
    # Executes the WebDAV request for a particular resource.
    def execute(head: false)
      if @resource.readable?
        return :ok if head

        [:ok, @resource.read]
      else
        :not_found
      end
    end
  end
end
