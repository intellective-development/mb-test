class Address
  module SegmentSerializer
    extend ActiveSupport::Concern

    def as_segment_address
      {
        city: city,
        state: state_name,
        address1: address1,
        address2: address2,
        zip_code: zip_code
      }
    end
  end
end
