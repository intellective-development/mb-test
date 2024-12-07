# This acts as an interface that defines the methods the classes that use it must implement.
module Dashboard
  module Integration
    module DashboardInterface
      def place_order(_shipment)
        raise NoMethodError
      end

      def cancel_order(_shipment)
        raise NoMethodError
      end

      def change_order_status(_shipment, _state)
        raise NoMethodError
      end
    end
  end
end
