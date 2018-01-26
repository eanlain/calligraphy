# frozen_string_literal: true

module Calligraphy
  # Miscellaneous general convenience methods.
  module Utils
    TRUE_VALUES = [true, 1, '1', 't', 'T', 'true', 'TRUE'].freeze
    FALSE_VALUES = [false, 0, '0', 'f', 'F', 'false', 'FALSE'].freeze

    # Determines if a value is truthy.
    def true?(val)
      TRUE_VALUES.include? val
    end

    # Determines if a value is falsy.
    def false?(val)
      FALSE_VALUES.include? val
    end

    # Joins paths.
    def join_paths(*paths)
      paths.join '/'
    end

    # Given a path and separator, splits the path string using the separator
    # and pops off the last element of the split array.
    def split_and_pop(path:, separator: '/')
      path.split(separator)[0..-2]
    end

    # Determines if object exists and if existing object is of a given type.
    def obj_exists_and_is_not_type?(obj:, type:)
      obj.nil? ? false : obj != type
    end

    # Given an array of hashes, returns an array of hash values.
    def map_array_of_hashes(arr_hashes)
      return if arr_hashes.nil?

      [].tap do |output_array|
        arr_hashes.each do |hash|
          output_array.push hash.values
        end
      end
    end

    # Extracts a lock token from an If headers.
    def extract_lock_token(if_header)
      token = if_header.scan(Calligraphy::LOCK_TOKEN_REGEX)
      token.flatten.first if token.is_a? Array
    end

    # Hash used in describing a supportedlock.
    def lockentry_hash(scope, type)
      { lockentry: { lockscope: scope, locktype: type } }
    end
  end
end
