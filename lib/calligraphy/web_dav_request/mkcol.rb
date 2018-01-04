# frozen_string_literal: true

module Calligraphy
  # Responsible for creating a new collection resource at the location
  # specified by the request.
  class Mkcol < WebDavRequest
    include Calligraphy::XML::Utils

    # Responsible for evaluating preconditions for the WebDAV request.
    def preconditions
      return :unsupported_media_type unless validate_request_body
      return [:forbidden, mkcol_response] unless validate_resourcetypes
    end

    # Executes the WebDAV request for a particular resource.
    def execute
      return :method_not_allowed if @resource.exists?
      return :conflict unless @resource.ancestor_exist?

      xml = @resource.enable_extended_mkcol? ? extended_mkcol_xml : nil

      @resource.create_collection

      post_mkcol_actions xml

      :created
    end

    private

    def validate_request_body
      xml = @resource.enable_extended_mkcol? ? extended_mkcol_xml : nil

      if xml == :bad_request
        false
      elsif @resource.enable_extended_mkcol?
        true
      else
        @resource.request_body.blank? ? false : true
      end
    end

    def validate_resourcetypes
      return true if body.blank?

      xml = search_xml_for(body: body, search: 'resourcetype').first
      resourcetypes = xml.children.map do |node|
        next unless node.is_a? Nokogiri::XML::Element

        node.name
      end.compact

      resourcetypes.each do |rt|
        return false unless @resource.valid_resourcetypes.include? rt
      end

      true
    end

    def mkcol_response
      xml_builder.mkcol_response prepare_mkcol_response_xml
    end

    def prepare_mkcol_response_xml
      nodes = search_xml_for(body: body, search: 'prop').first.children

      separate_nodes_by_name nodes, 'resourcetype'
    end

    def extended_mkcol_xml
      return nil if body.blank?

      # The `mkcol` tag specifies properties to be set in an extended MKCOL
      # request, as well as any additional information needed when creating
      # the resource.
      xml_for body: body, node: 'mkcol'
    end

    def post_mkcol_actions(xml)
      apply_extended_mkcol_properties xml

      set_content_location_header
    end

    def apply_extended_mkcol_properties(xml)
      return nil if xml.nil?

      @resource.proppatch xml
    end

    def set_content_location_header
      @response.headers['Content-Location'] = @resource.full_request_path
    end
  end
end
