# frozen_string_literal: true

require 'sentry/rack/capture_exceptions'
require 'doorkeeper/grape/helpers'

# RetailerAPIV1
class RetailerAPIV1 < BaseAPIV2
  use Sentry::Rack::CaptureExceptions

  format :json
  prefix 'api/retailers'
  version 'v1', using: :path

  error_formatter :json, ErrorFormatter

  helpers Doorkeeper::Grape::Helpers

  mount RetailerAPIV1::ShipmentsEndpoint
end
