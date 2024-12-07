require 'doorkeeper/grape/helpers'

class PartnerAPIV1 < BaseAPIV1
  helpers Doorkeeper::Grape::Helpers
  # TECH-4253: Partners-only endoints, only products by now

  format :json
  prefix 'api/partner'
  version 'v1', using: :path

  before do
    doorkeeper_authorize!
  end

  mount PartnerAPIV1::ProductsEndpoint
end
