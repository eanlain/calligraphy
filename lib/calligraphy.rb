# frozen_string_literal: true

require 'calligraphy/rails/mapper'
require 'calligraphy/rails/web_dav_methods'
require 'calligraphy/rails/web_dav_preconditions'
require 'calligraphy/rails/web_dav_requests_controller'

require 'calligraphy/xml/web_dav_elements'
require 'calligraphy/xml/builder'
require 'calligraphy/xml/utils'

require 'calligraphy/utils'
require 'calligraphy/resource/resource'
require 'calligraphy/resource/file_resource'

require 'calligraphy/web_dav_request/web_dav_request'
require 'calligraphy/web_dav_request/copy'
require 'calligraphy/web_dav_request/delete'
require 'calligraphy/web_dav_request/get'
require 'calligraphy/web_dav_request/lock'
require 'calligraphy/web_dav_request/mkcol'
require 'calligraphy/web_dav_request/move'
require 'calligraphy/web_dav_request/propfind'
require 'calligraphy/web_dav_request/proppatch'
require 'calligraphy/web_dav_request/put'
require 'calligraphy/web_dav_request/unlock'

#:nodoc:
module Calligraphy
  # Constants used throughout Calligraphy.
  DAV_NS = 'DAV:'
  DAV_NO_LOCK_REGEX = /DAV:no-lock/i
  DAV_NOT_NO_LOCK_REGEX = /Not\s+<DAV:no-lock>/i
  ETAG_IF_REGEX = /\[(.+?)\]/
  INFINITY = 1.0 / 0.0 unless defined? INFINITY
  LOCK_TOKEN_ANGLE_REGEX = /[<>]/
  LOCK_TOKEN_REGEX = /<(urn:uuid:.+?)>/
  RESOURCE_REGEX = /^<+(.+?)>\s/
  TAGGED_LIST_REGEX = /\)\s</
  UNTAGGAGED_LIST_REGEX = /\)\s\(/

  # HTTP methods allowed by the WebDavRequests controller.
  mattr_accessor :allowed_http_methods
  @@allowed_http_methods = %w[
    options get put delete copy move
    mkcol propfind proppatch lock unlock
  ]

  # Proc responsible for returning the user's password, API key,
  # or HA1 digest hash so that Rails can check user credentials.
  # Should be overridden to handle your particular application's
  # user and/or authentication setup.
  mattr_accessor :digest_password_procedure
  @@digest_password_procedure = proc { |_username| 'changeme!' }

  # If Digest Authentication is enabled by default.
  mattr_accessor :enable_digest_authentication
  @@enable_digest_authentication = false

  # The realm used in HTTP Digest Authentication.
  mattr_accessor :http_authentication_realm
  @@http_authentication_realm = 'Application'

  # Maximum lock lifetime in seconds.
  mattr_accessor :lock_timeout_period
  @@lock_timeout_period = 86_400

  # The HTTP actions Calligraphy uses to create mappings between WebDAV
  # HTTP verbs and URLs and WebDAV controller actions.
  mattr_accessor :web_dav_actions
  @@web_dav_actions = %i[
    options get put delete copy move
    mkcol propfind proppatch lock unlock
  ]

  # Default way to set up Calligraphy.
  # Run `rails generate calligraphy:install` to generate a
  # fresh initializer with all configuration values.
  def self.configure
    yield self
  end
end
