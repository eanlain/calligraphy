# frozen_string_literal: true

module Calligraphy
  # Responsible for taking out a lock of any access type and refreshing
  # existing locks.
  class Lock < WebDavRequest
    include Calligraphy::XML::Utils

    attr_reader :resource_exists

    #:nodoc:
    def initialize(headers:, request:, response:, resource:)
      super

      # Determine is resource already exists before lock operation.
      @resource_exists = @resource.exists?
    end

    # Executes the WebDAV request for a particular resource.
    def execute
      if refresh_lock?
        lock_properties = @resource.refresh_lock
      elsif resource_locked?
        return :locked
      else
        # The `lockinfo` tag is used to specify the type of lock the client
        # wishes to have created.
        xml = xml_for body: body, node: 'lockinfo'
        return :bad_request if xml == :bad_request

        lock_properties = @resource.lock xml, @headers['Depth']
      end

      build_response lock_properties
    end

    private

    def refresh_lock?
      @resource.request_body.blank? && !@resource.locked_to_user?(@headers)
    end

    def resource_locked?
      (@resource.locked? && @resource.lock_is_exclusive?) ||
        (@resource.locked_to_user?(@headers) && !xml_contains_shared_lock?)
    end

    def xml_contains_shared_lock?
      lock_type = nil
      xml = xml_for body: body, node: 'lockinfo'

      xml.each do |node|
        next unless node.is_a? Nokogiri::XML::Element

        lock_type = node.children[0].name if node.name == 'lockscope'
      end

      lock_type == 'shared'
    end

    def build_response(lock_properties)
      builder = xml_builder
      xml_res = builder.lock_response lock_properties

      lock_token = extract_lock_token lock_properties
      prepare_response_headers lock_token

      response_status xml_res
    end

    def extract_lock_token(properties)
      properties
        .last
        .select { |x| x.name == 'locktoken' }[0]
        .children
        .text
        .strip
    end

    def prepare_response_headers(lock_token)
      response.headers['Lock-Token'] = "<#{lock_token}>"

      set_xml_content_type
    end

    def response_status(xml_res)
      return :ok, xml_res if @resource_exists
      [:created, xml_res]
    end
  end
end
