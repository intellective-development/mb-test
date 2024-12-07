class SupplierAPIV2::SupplierEndpoint::PackageSizePresetsEndpoint < BaseAPIV2
  helpers Shared::Helpers::Supplier::PackageSizePresetHelper, Shared::Helpers::Supplier::PackageSizePresetParamHelper

  helpers do
    def set_package_size_preset
      @package_size_preset = current_supplier.package_size_presets.find_by(id: params[:id])

      error!('Package size preset not found', 404) if @package_size_preset.nil?
    end
  end

  before do
    authorize!
  end

  namespace :supplier do
    namespace :package_size_presets do
      params do
        use :package_size_preset_params
      end

      desc 'Create package size presets for the delegate supplier.'
      post do
        error!('Package size presets can only be created from main or delegated store', 422) if current_supplier.delegating?

        @package_size_preset = current_supplier.package_size_presets.new
        @package_size_preset.assign_attributes(permitted_supplier_package_size_preset_params(params))

        if @package_size_preset.save
          status 201
          present @package_size_preset, with: SupplierAPIV2::Entities::Supplier::PackageSizePreset
        else
          error!(@package_size_preset.errors.full_messages.to_sentence, 422)
        end
      end

      desc "Get current supplier's package size presets"
      get do
        status 200

        @package_size_presets = if current_supplier.delegating?
                                  current_supplier.delegate.package_size_presets
                                else
                                  current_supplier.package_size_presets
                                end

        present @package_size_presets, with: SupplierAPIV2::Entities::Supplier::PackageSizePreset
      end

      route_param :id do
        desc 'Update a given package size preset of the current supplier'
        put do
          error!('Package size presets can only be updated from main or delegated store', 422) if current_supplier.delegating?

          set_package_size_preset

          if @package_size_preset.update(permitted_supplier_package_size_preset_params(params))
            status 200
            present @package_size_preset, with: SupplierAPIV2::Entities::Supplier::PackageSizePreset
          else
            error!(@package_size_preset.errors.full_messages.to_sentence, 422)
          end
        end

        desc 'Delete a given package size preset of the current supplier'
        delete do
          error!('Package size presets can only be deleted from main or delegated store', 422) if current_supplier.delegating?

          set_package_size_preset

          if @package_size_preset.destroy
            body false
          else
            error!(@package_size_preset.errors.full_messages.to_sentence, 422)
          end
        end
      end
    end
  end
end
