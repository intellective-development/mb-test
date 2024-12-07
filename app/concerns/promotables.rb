module Promotables
  extend ActiveSupport::Concern

  included do
    helper_method :promotable_suppliers, :promotable_options, :promotable_name,
                  :promotable_types
  end

  protected

  def promotable_suppliers
    @promotable_suppliers ||= Supplier.select(%i[name id]).order(:name).map { |s| [s.name, s.id] }
  end

  def promotable_options(ptype)
    case ptype
    when 'Supplier'
      promotable_suppliers
    end
  end

  def promotable_name(model)
    model.name
  end

  def promotable_types
    [%w[Supplier Supplier]]
  end
end
