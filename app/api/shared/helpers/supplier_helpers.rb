module Shared::Helpers::SupplierHelpers
  def load_suppliers(options = { allow_empty: false })
    if params[:supplier_id].present?
      @supplier_ids = params[:supplier_id]
                      .split(',')
                      .select { |b| b.to_s[/\d+$/] }
                      .uniq
                      .map(&:to_i)

      @suppliers = Supplier.includes(:profile, :shipping_methods)
                           .active
                           .where(id: @supplier_ids)
                           .order(:supplier_type_id, :name)

      if params[:shipping_state].present? && !@suppliers.where(allow_dtc_overlap: false).exists?
        @suppliers = (@suppliers + ShippingSupplierService.new(params[:shipping_state]).call).uniq
        @supplier_ids = @suppliers.map(&:id)
      end

      @supplier = @suppliers.first
      error! 'Supplier not found.', 404 if @supplier.nil? && !options[:allow_empty]
    end
  end
end
