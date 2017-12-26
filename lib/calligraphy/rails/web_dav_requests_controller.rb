module Calligraphy::Rails
  class WebDavRequestsController < ActionController::Base
    before_action :verify_resource_scope
    before_action :authenticate_with_digest_authentiation
    before_action :set_resource

    # Entry-point for all WebDAV requests. Handles checking and validating
    # preconditions, directing of requests to the proper WebDAV action
    # method, and composing responses to send back to the client.
    def invoke_method
      method = request.request_method.downcase

      if check_preconditions
        if method == 'head'
          status = get head: true
        elsif Calligraphy.allowed_http_methods.include? method
          set_resource_client_nonce(method) if Calligraphy.enable_digest_authentication

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

    # Prevent any request with `.` or `..` as part of the resource ID.
    def verify_resource_scope
      head :forbidden if %w(. ..).any? { |seg| params[:resource].include? seg }
    end

    def authenticate_with_digest_authentiation
      return unless Calligraphy.enable_digest_authentication

      realm = Calligraphy.http_authentication_realm

      authenticate_or_request_with_http_digest(realm) do |username|
        Calligraphy.digest_password_procedure.call(username)
      end
    end

    def set_resource
      resource_id = if params[:format]
        [params[:resource], params[:format]].join '.'
      else
        params[:resource]
      end

      @resource_class = params[:resource_class] || Calligraphy::Resource
      @resource_root_path = params[:resource_root_path]

      @resource = @resource_class.new resource: resource_id, req: request, root_dir: @resource_root_path
    end

    def check_preconditions
      return true unless request.headers['If'].present?

      evaluate_if_header
    end

    def evaluate_if_header
      conditions_met = false
      condition_lists = get_if_conditions

      condition_lists.each do |list|
        conditions = parse_preconditions list

        conditions_met = evaluate_preconditions conditions
        break if conditions_met
      end

      conditions_met
    end

    def get_if_conditions
      lists = if request.headers['If'][0] == '<'
        request.headers['If'].split Calligraphy::TAGGED_LIST_REGEX
      else
        request.headers['If'].split Calligraphy::UNTAGGAGED_LIST_REGEX
      end

      lists
    end

    def parse_preconditions(list)
      conditions = { dav_no_lock: nil, etag: nil, lock_token: nil, resource: nil }

      conditions[:dav_no_lock] = if list =~ Calligraphy::DAV_NO_LOCK_REGEX
        list =~ Calligraphy::DAV_NOT_NO_LOCK_REGEX ? nil : true
      end

      if list =~ Calligraphy::RESOURCE_REGEX
        conditions[:resource] = list.scan(Calligraphy::RESOURCE_REGEX).flatten[0]
      end

      if list =~ Calligraphy::LOCK_TOKEN_REGEX
        conditions[:lock_token] = list.scan(Calligraphy::LOCK_TOKEN_REGEX).flatten[0]
      end

      if list =~ Calligraphy::ETAG_IF_REGEX
        conditions[:etag] = list.scan(Calligraphy::ETAG_IF_REGEX).flatten[0]
      end

      conditions
    end

    def evaluate_preconditions(conditions)
      conditions_met = true
      target = if conditions[:resource]
        @resource_class.new(
          resource: conditions[:resource],
          mount: @resource.mount_point
        )
      else
        @resource
      end

      if conditions[:lock_token]
        if target.locked?
          conditions_met = false unless target.lock_tokens&.include? conditions[:lock_token]
        else
          conditions_met = false if target.locked_to_user? request.headers
        end
      end

      if conditions[:etag]
        validators = [@resource.etag, '']
        conditions_met = false unless validate_etag validators, conditions[:etag]
      end

      conditions_met = false if conditions[:dav_no_lock]
      conditions_met
    end

    def validate_etag(etag_validators, validate_against)
      cache_key = ActiveSupport::Cache.expand_cache_key etag_validators

      "W/\"#{Digest::MD5.hexdigest(cache_key)}\"" == validate_against
    end

    def web_dav_request
      { headers: request.headers, request: request, resource: @resource, response: response }
    end

    def set_resource_client_nonce(method)
      @resource.client_nonce = get_client_nonce
    end

    def get_client_nonce
      auth_header = request.headers['HTTP_AUTHORIZATION']

      auth = ::ActionController::HttpAuthentication::Digest.decode_credentials auth_header
      auth[:cnonce]
    end

    def options
      response.headers['DAV'] = @resource.dav_compliance

      :ok
    end

    def get(head: false)
      fresh_when(@resource, etag: @resource.etag) if @resource.readable?

      Calligraphy::Get.new(web_dav_request).request(head: head)
    end

    def put
      Calligraphy::Put.new(web_dav_request).request
    end

    def delete
      Calligraphy::Delete.new(web_dav_request).request
    end

    def copy
      Calligraphy::Copy.new(web_dav_request).request
    end

    def move
      Calligraphy::Move.new(web_dav_request).request
    end

    def mkcol
      Calligraphy::Mkcol.new(web_dav_request).request
    end

    def propfind
      Calligraphy::Propfind.new(web_dav_request).request
    end

    def proppatch
      Calligraphy::Proppatch.new(web_dav_request).request
    end

    def lock
      Calligraphy::Lock.new(web_dav_request).request
    end

    def unlock
      Calligraphy::Unlock.new(web_dav_request).request
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
