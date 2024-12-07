module Shared::Helpers::Supplier::PackageSizePresetParamHelper
  extend Grape::API::Helpers

  params :package_size_preset_params do
    requires :package_size_preset, type: Hash do
      requires :bottle_count, type: Integer, allow_blank: false
      requires :dimensions, type: Hash, allow_blank: false do
        requires :length, type: String, allow_blank: false
        requires :width, type: String, allow_blank: false
        requires :height, type: String, allow_blank: false
      end
      requires :weight, type: Hash, allow_blank: false do
        requires :value, type: String, allow_blank: false
        requires :unit, type: String, allow_blank: false
      end
    end
  end
end
