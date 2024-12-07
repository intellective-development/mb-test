module Shared::Helpers::Supplier::PackageSizePresetHelper
  def permitted_supplier_package_size_preset_params(params)
    clean_params(params[:package_size_preset]).permit(:bottle_count, dimensions: %i[length width height], weight: %i[value unit])
  end
end
