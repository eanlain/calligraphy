# frozen_string_literal: true

module Calligraphy
  # Responsible for creating a new collection resource at the location
  # specified by the request.
  class Mkcol < WebDavRequest
    # Executes the WebDAV request for a particular resource.
    def execute
      return :method_not_allowed if @resource.exists?
      return :conflict unless @resource.ancestor_exist?
      return :unsupported_media_type unless @resource.request_body.blank?

      @resource.create_collection
      set_content_location_header

      :created
    end

    private

    def set_content_location_header
      @response.headers['Content-Location'] = @resource.full_request_path
    end
  end
end
