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
require 'calligraphy/copy'
require 'calligraphy/delete'
require 'calligraphy/get'
require 'calligraphy/lock'
require 'calligraphy/mkcol'
require 'calligraphy/move'
require 'calligraphy/propfind'
require 'calligraphy/proppatch'
require 'calligraphy/put'
require 'calligraphy/unlock'

module Calligraphy
  DAV_NS = 'DAV:'
  DAV_NO_LOCK_REGEX = /DAV:no-lock/i
  DAV_NOT_NO_LOCK_REGEX = /Not\s+<DAV:no-lock>/i
  ETAG_IF_REGEX = /\[(.+?)\]/
  LOCK_TOKEN_ANGLE_REGEX = /[<>]/
  LOCK_TOKEN_REGEX = /<(urn:uuid:.+?)>/
  RESOURCE_REGEX = /^<+(.+?)>\s/
  TAGGED_LIST_REGEX = /\)\s</
  UNTAGGAGED_LIST_REGEX = /\)\s\(/

  mattr_accessor :allowed_methods
  @@allowed_methods = %w(
    options head get put delete copy move mkcol propfind proppatch lock unlock
  )

  mattr_accessor :digest_password_procedure
  @@digest_password_procedure = Proc.new { |x| 'changeme!' }

  mattr_accessor :enable_digest_authentication
  @@enable_digest_authentication = false

  mattr_accessor :lock_timeout_period
  @@lock_timeout_period = 24 * 60 * 60

  mattr_accessor :web_dav_actions
  @@web_dav_actions = %i(
    options get put delete copy move mkcol propfind proppatch lock unlock
  )

  def self.configure
    yield self
  end
end
