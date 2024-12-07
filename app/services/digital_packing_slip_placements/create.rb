module DigitalPackingSlipPlacements
  class Create
    attr_reader :params

    def initialize(params)
      @params = params
    end

    def call
      @success = digital_packing_slip_placement.save

      self
    end

    def digital_packing_slip_placement
      @digital_packing_slip_placement ||= DigitalPackingSlipPlacement.new(params)
    end

    def success?
      @success
    end
  end
end
