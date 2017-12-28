# frozen_string_literal: true

Calligraphy.configure do |config|
  # The HTTP actions Calligraphy uses to create mappings between WebDAV
  # HTTP verbs and URLs and WebDAV controller actions.
  # config.web_dav_actions = [
  #   :options, :get, :put, :delete, :copy, :move,
  #   :mkcol, :propfind, :proppatch, :lock, :unlock
  # ]

  # HTTP methods allowed by the WebDavRequests controller.
  # Before responding to a WebDav request, the WebDavRequests controller
  # checks this list to determine if it is allowed to make the request.
  # If a method is disallowed, the controller will respond by sending an
  # HTTP 405 (Method Not Allowed) response.
  # config.allowed_http_methods = %w(
  #   options get put delete copy move
  #   mkcol propfind proppatch lock unlock
  # )

  # If Digest Authentication is enabled by default. False by default.
  # config.enable_digest_authentication = false

  # Proc responsible for returning the user's password, API key,
  # or HA1 digest hash so that Rails can check user credentials.
  # Should be configured to handle your particular application's
  # user and/or authentication setup.
  #
  # For example, in an API setup where an email/API key are sent with the
  # request, in lieu of a username/password, the digest_password_procedure
  # would be defined as:
  #
  #     config.digest_password_procedure = Proc.new do |email|
  #       u = User.find_by(email: email)
  #       u.authentication_token
  #     end
  #
  # Digest Authentication would need to be enabled for this proc to
  # actually be called.
  # config.digest_password_procedure = Proc.new do |username|
  #   'changeme!'
  # end

  # The realm used in HTTP Digest Authentication. 'Application' by default.
  # config.http_authentication_realm = 'Application'

  # Maximum lock lifetime in seconds. 86400 by default.
  # config.lock_timeout_period = 86400
end
