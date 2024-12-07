module BusinessSuppliers
  class Update
    attr_reader :params, :business_supplier

    def initialize(business_supplier, params)
      @business_supplier = business_supplier
      @params            = params
    end

    def call
      @success = business_supplier.update(params)

      self
    end

    def success?
      @success
    end
  end
end
