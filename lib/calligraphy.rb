require 'calligraphy/rails/mapper'
require 'calligraphy/rails/web_dav_requests_controller'

require 'calligraphy/xml/builder'
require 'calligraphy/xml/namespace'
require 'calligraphy/xml/node'
require 'calligraphy/xml/utils'

require 'calligraphy/utils'
require 'calligraphy/resource'
require 'calligraphy/file_resource'

require 'calligraphy/web_dav_request'

module Calligraphy
  DAV_NS = 'DAV:'
  LOCK_TOKEN_REGEX = /<(urn:uuid:.+?)>/

  mattr_accessor :allowed_methods
  @@allowed_methods = %w(
    options head get put delete copy move mkcol propfind proppatch lock unlock
  )

  mattr_accessor :lock_timeout_period
  @@lock_timeout_period = 24 * 60 * 60

  mattr_accessor :web_dav_actions
  @@web_dav_actions = %i(
    options get put delete copy move mkcol propfind proppatch lock unlock
  )
end
