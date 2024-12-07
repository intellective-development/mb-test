require 'sentry/rack/capture_exceptions'

class MikmakAPIV1 < BaseAPIV1
  use Sentry::Rack::CaptureExceptions

  format :json
  prefix 'api/mikmak'
  version 'v1', using: :path

  error_formatter :json, ErrorFormatter

  mount MikmakAPIV1::ProductsEndpoint
  mount MikmakAPIV1::CartEndpoint
end
