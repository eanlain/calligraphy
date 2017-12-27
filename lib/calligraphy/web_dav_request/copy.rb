# frozen_string_literal: true

module Calligraphy
  # Responsible for creating a duplicate of the source resource identified
  # by the request to the destination resource identified by the URI in
  # the Destination header.
  class Copy < WebDavRequest
    # Executes the WebDAV request for a particular resource.
    def execute
      options = copy_move_options
      can_copy = @resource.can_copy? options

      unless can_copy[:can_copy]
        return :precondition_failed if can_copy[:ancestor_exist]
        return :conflict
      end

      return :locked if can_copy[:locked]

      overwritten = @resource.copy options
      overwritten ? :no_content : :created
    end

    private

    def copy_move_options
      {
        depth: @headers['Depth'],
        destination: remove_trailing_slash(destination_header),
        overwrite: @headers['Overwrite'] || true
      }
    end

    def destination_header
      @headers['Destination'].split(@headers['Host'])[-1]
    end

    def remove_trailing_slash(input)
      input[-1] == '/' ? input[0..-2] : input
    end
  end
end
