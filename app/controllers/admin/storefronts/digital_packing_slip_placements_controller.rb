module Admin
  module Storefronts
    class DigitalPackingSlipPlacementsController < Admin::BaseController
      delegate      :sort_column, :sort_direction, to: :list_digital_packing_slip_placements
      helper_method :sort_column, :sort_direction
      before_action :load_storefront
      before_action :load_digital_packing_slip_placement, only: %i[edit update destroy]

      def index
        @digital_packing_slip_placements = list_digital_packing_slip_placements.result
      end

      def new
        @digital_packing_slip_placement = DigitalPackingSlipPlacement.new
      end

      def create
        redirect_to(action: :index) and return if create_digital_packing_slip_placement.success?

        @digital_packing_slip_placement = create_digital_packing_slip_placement.digital_packing_slip_placement
        flash[:error] = 'The Digital Packing Slip Placement could not be saved'
        render action: :new
      end

      def update
        redirect_to(action: :index) and return if update_digital_packing_slip_placement.success?

        flash[:error] = 'The Digital Packing Slip Placement could not be updated'
        render action: :edit
      end

      def destroy
        redirect_to(action: :index) and return if delete_digital_packing_slip_placement.success?

        flash[:error] = 'The Digital Packing Slip Placement could not be deleted'
        redirect_to(action: :index)
      end

      private

      def list_digital_packing_slip_placements
        @list_digital_packing_slip_placements ||= ::DigitalPackingSlipPlacements::List.new(params).call
      end

      def create_digital_packing_slip_placement
        ::DigitalPackingSlipPlacements::Create.new(digital_packing_slip_placement_params).call
      end

      def update_digital_packing_slip_placement
        ::DigitalPackingSlipPlacements::Update
          .new(@digital_packing_slip_placement, digital_packing_slip_placement_params).call
      end

      def delete_digital_packing_slip_placement
        ::DigitalPackingSlipPlacements::Delete.new(@digital_packing_slip_placement).call
      end

      def load_storefront
        @storefront = Storefront.find(params[:storefront_id])
      end

      def load_digital_packing_slip_placement
        @digital_packing_slip_placement =
          DigitalPackingSlipPlacement.find_by(id: params[:id], storefront_id: params[:storefront_id])
      end

      def digital_packing_slip_placement_params
        params.require(:digital_packing_slip_placement).permit(
          :title, :tag, :link, :description, :image
        ).merge(params.permit(:storefront_id))
      end
    end
  end
end
