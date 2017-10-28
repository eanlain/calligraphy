module Calligraphy
  class Mkcol < WebDavRequest
    def request
      return :method_not_allowed if @resource.exists?
      return :conflict unless @resource.ancestor_exist?
      return :unsupported_media_type unless @resource.request_body.blank?

      @resource.create_collection
      set_content_location_header
      
      return :created
    end

    private

    def set_content_location_header
      @response.headers['Content-Location'] = @resource.full_request_path
    end
  end
end
