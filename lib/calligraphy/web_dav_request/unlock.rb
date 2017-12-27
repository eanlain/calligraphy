# frozen_string_literal: true

module Calligraphy
  # Responsible for removing the lock identified by the lock token in the
  # request header.
  class Unlock < WebDavRequest
    # Executes the WebDAV request for a particular resource.
    def execute
      return :bad_request if @headers['Lock-Token'].nil?

      @resource.unlock lock_token_header
    end

    private

    def lock_token_header
      @headers['Lock-Token'].gsub Calligraphy::LOCK_TOKEN_ANGLE_REGEX, ''
    end
  end
end
