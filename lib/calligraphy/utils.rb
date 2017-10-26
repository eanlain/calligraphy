module Calligraphy
  module Utils
    TRUE_VALUES = [true, 1, '1', 't', 'T', 'true', 'TRUE']
    FALSE_VALUES = [false, 0, '0', 'f', 'F', 'false', 'FALSE']

    def is_true?(val)
      TRUE_VALUES.include? val
    end

    def is_false?(val)
      FALSE_VALUES.include? val
    end

    def join_paths(*paths)
      paths.join '/'
    end

    def split_and_pop(path:, separator: '/')
      path.split(separator)[0..-2]
    end
  end
end
