module Calligraphy
  class Unlock < WebDavRequest
    def request
      return :bad_request if @headers['Lock-Token'].nil?

      @resource.unlock lock_token_header
    end

    private

    def lock_token_header
      @headers['Lock-Token'].gsub Calligraphy::LOCK_TOKEN_ANGLE_REGEX, ''
    end
  end
end
