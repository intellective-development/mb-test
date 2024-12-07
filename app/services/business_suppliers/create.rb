module BusinessSuppliers
  class Create
    attr_reader :supplier, :params

    def initialize(supplier, params)
      @supplier = supplier
      @params   = params
    end

    def call
      @success = business_supplier.save

      self
    end

    def business_supplier
      @business_supplier ||= BusinessSupplier.new(supplier: supplier, **params)
    end

    def success?
      @success
    end
  end
end
