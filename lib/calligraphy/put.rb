module Calligraphy
  class Put < WebDavRequest
    def request
      return :locked if @resource.locked_to_user? headers
      return :method_not_allowed if @resource.collection?

      @resource.write

      return :created, @resource.contents
    end
  end
end
