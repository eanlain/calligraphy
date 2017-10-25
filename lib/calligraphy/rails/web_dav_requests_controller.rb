module Calligraphy::Rails
  class WebDavRequestsController < ActionController::Base
    before_action :verify_resource_scope
    before_action :set_resource

    def invoke_method
      method = request.request_method.downcase

      if check_preconditions
        if method == 'head'
          status = get head: true
        elsif Calligraphy.allowed_methods.include? method
          status, body = send method
        else
          status = :method_not_allowed
        end

        send_response status: status, body: body
      else
        send_response status: :precondition_failed
      end
    end

    private

    def verify_resource_scope
      head :forbidden if params[:resource].include? '..'
    end

    def set_resource
      resource_id = if params[:format]
        [params[:resource], params[:format]].join '.'
      else
        params[:resource]
      end

      @resource_class = params[:resource_class]
      @resource = @resource_class.new resource: resource_id, req: request
    end

    def send_response(status:, body: nil)
      if body.nil?
        head status
      else
        render body: body, status: status
      end
    end
  end
end
