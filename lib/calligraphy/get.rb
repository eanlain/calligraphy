module Calligraphy
  class Get < WebDavRequest
    def request(head: false)
      if @resource.readable?
        return :ok if head
        return :ok, @resource.read
      else
        return :not_found
      end
    end
  end
end
