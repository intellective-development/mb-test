module DigitalPackingSlipPlacements
  class Delete
    attr_reader :digital_packing_slip_placement

    def initialize(digital_packing_slip_placement)
      @digital_packing_slip_placement = digital_packing_slip_placement
    end

    def call
      digital_packing_slip_placement.destroy
      self
    end

    def success?
      digital_packing_slip_placement.destroyed?
    end
  end
end
