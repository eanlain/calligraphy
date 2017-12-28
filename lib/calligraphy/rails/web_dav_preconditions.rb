# frozen_string_literal: true

module Calligraphy
  module Rails
    # Provides methods to handle checking and validating WebDAV request
    # preconditions.
    module WebDavPreconditions
      private

      def check_preconditions
        return true unless request.headers['If'].present?

        evaluate_if_header
      end

      def evaluate_if_header
        conditions_met = false
        condition_lists = if_conditions

        condition_lists.each do |list|
          conditions = parse_preconditions list

          conditions_met = evaluate_preconditions conditions
          break if conditions_met
        end

        conditions_met
      end

      def if_conditions
        if request.headers['If'][0] == '<'
          request.headers['If'].split Calligraphy::TAGGED_LIST_REGEX
        else
          request.headers['If'].split Calligraphy::UNTAGGAGED_LIST_REGEX
        end
      end

      def parse_preconditions(list)
        conditions = conditions_hash
        conditions[:dav_no_lock] = match_dav_no_lock list
        conditions[:resource] = scan_for_resource list
        conditions[:lock_token] = scan_for_lock_token list
        conditions[:etag] = scan_for_etag list
        conditions
      end

      def conditions_hash
        {
          dav_no_lock: nil,
          etag: nil,
          lock_token: nil,
          resource: nil
        }
      end

      def match_dav_no_lock(list)
        return nil unless list =~ Calligraphy::DAV_NO_LOCK_REGEX

        list =~ Calligraphy::DAV_NOT_NO_LOCK_REGEX ? nil : true
      end

      def scan_for_resource(list)
        return nil unless list =~ Calligraphy::RESOURCE_REGEX

        list.scan(Calligraphy::RESOURCE_REGEX).flatten[0]
      end

      def scan_for_lock_token(list)
        return nil unless list =~ Calligraphy::LOCK_TOKEN_REGEX

        list.scan(Calligraphy::LOCK_TOKEN_REGEX).flatten[0]
      end

      def scan_for_etag(list)
        return nil unless list =~ Calligraphy::ETAG_IF_REGEX

        list.scan(Calligraphy::ETAG_IF_REGEX).flatten[0]
      end

      def evaluate_preconditions(conditions)
        conditions_met = true

        if conditions[:etag]
          conditions_met = false unless evaluate_etag_condition conditions
        end

        conditions_met = false if conditions[:dav_no_lock]
        conditions_met
      end

      def target_resource(conditions)
        if conditions[:resource]
          @resource_class.new(
            resource: conditions[:resource],
            mount: @resource.mount_point
          )
        else
          @resource
        end
      end

      def evaluate_etag_condition(conditions)
        validators = [@resource.etag, '']
        validate_etag validators, conditions[:etag]
      end

      def validate_etag(etag_validators, validate_against)
        cache_key = ActiveSupport::Cache.expand_cache_key etag_validators

        validate_against == "W/\"#{Digest::MD5.hexdigest(cache_key)}\""
      end
    end
  end
end
