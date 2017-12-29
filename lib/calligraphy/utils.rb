# frozen_string_literal: true

module Calligraphy
  # Miscellaneous convenience methods.
  module Utils
    TRUE_VALUES = [true, 1, '1', 't', 'T', 'true', 'TRUE'].freeze
    FALSE_VALUES = [false, 0, '0', 'f', 'F', 'false', 'FALSE'].freeze

    def true?(val)
      TRUE_VALUES.include? val
    end

    def false?(val)
      FALSE_VALUES.include? val
    end

    def join_paths(*paths)
      paths.join '/'
    end

    def split_and_pop(path:, separator: '/')
      path.split(separator)[0..-2]
    end

    def obj_exists_and_is_not_type?(obj:, type:)
      obj.nil? ? false : obj != type
    end

    def map_array_of_hashes(arr_hashes)
      [].tap do |output_array|
        arr_hashes.each do |hash|
          output_array.push(hash.map { |_k, v| v })
        end
      end
    end

    def extract_lock_token(if_header)
      token = if_header.scan(Calligraphy::LOCK_TOKEN_REGEX)
      token.flatten.first if token.is_a? Array
    end

    def lockentry_hash(scope, type)
      { lockentry: { lockscope: scope, locktype: type } }
    end
  end
end
