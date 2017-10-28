module Calligraphy
  class Copy < WebDavRequest
    def request
      options = copy_move_options
      can_copy = @resource.can_copy? options

      if can_copy[:ancestor_exist]
        return :precondition_failed
      else
        return :conflict
      end unless can_copy[:can_copy]

      return :locked if can_copy[:locked]

      overwritten = @resource.copy options
      return overwritten ? :no_content : :created
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
