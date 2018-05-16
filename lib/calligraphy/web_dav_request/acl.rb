# frozen_string_literal: true

module Calligraphy
  # TODO: CHANGE DESCRIPTIONS
  # Responsible for processing instructions specified in the request body
  # to set and/or remove properties defined on the resource.
  class Acl < WebDavRequest
    include Calligraphy::XML::Utils
    # include Calligraphy::AclUtils

    # Responsible for evaluating preconditions for the WebDAV request.
    def preconditions
      # conflict_preconditions
      # forbidden_preconditions
    end

    # Executes the WebDAV request for a particular resource.
    def execute
      return :locked if @resource.locked_to_user? @headers

      # The `acl` tag contains the request to modify the access control list
      # of a resource.
      xml = xml_for body: body, node: 'acl'
      return :bad_request if xml == :bad_request

      ace = search_xml_for body: body, search: 'ace'

      binding.pry
      @resource.acl ace

      :ok
    end

    private

    # Array with compact and first?
    def conflict_preconditions
      [
        no_ace_conflict,
        no_protected_ace_conflict,
        no_inherited_ace_conflict
      ].compact.first
    end

    def forbidden_preconditions
      [
        limited_number_of_aces,
        deny_before_grant,
        grant_only,
        no_invert,
        no_abstract,
        not_supported_priviledge,
        missing_required_principal,
        recognized_principal,
        allowed_principal
      ].compact.first
    end

    def build_error(response)
      { error: response }
    end

    def no_ace_conflict
      build_error 'no_ace_conflict'
    end

    def no_protected_ace_conflict
      build_error 'no-protected-ace-conflict'
    end

    def no_inherited_ace_conflict
      build_error 'no-inherited-ace-conflict'
    end

    def limited_number_of_aces
      build_error 'limited-number-of-aces'
    end

    def deny_before_grant
      build_error 'deny-before-grant'
    end

    def grant_only
      build_error 'grant-only'
    end

    def no_invert
      build_error 'no-invert'
    end

    def no_abstract
      build_error 'no-abstract'
    end

    def not_supported_privilege
      build_error 'not-supported-priviledge'
    end

    def missing_required_principal
      build_error 'missing-required-principal'
    end

    def recognized_principal
      build_error 'recognized-principal'
    end

    def allowed_principal
      build_error 'allowed-principal'
    end
  end
end
