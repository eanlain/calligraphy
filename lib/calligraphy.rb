require 'calligraphy/rails/mapper'
require 'calligraphy/rails/web_dav_requests_controller'

require 'calligraphy/xml/builder'
require 'calligraphy/xml/namespace'
require 'calligraphy/xml/node'
require 'calligraphy/xml/utils'

require 'calligraphy/utils'
require 'calligraphy/resource'

require 'calligraphy/web_dav_request'

module Calligraphy
  DAV_NS = 'DAV:'

  mattr_accessor :web_dav_actions
  @@web_dav_actions = %i(
    options get put delete copy move mkcol propfind proppatch lock unlock
  )
end
