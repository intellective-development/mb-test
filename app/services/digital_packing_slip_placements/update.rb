module DigitalPackingSlipPlacements
  class Update
    attr_reader :params, :digital_packing_slip_placement

    def initialize(digital_packing_slip_placement, params)
      @digital_packing_slip_placement = digital_packing_slip_placement
      @params = params
    end

    def call
      @success = digital_packing_slip_placement.update(params)

      self
    end

    def success?
      @success
    end
  end
end
