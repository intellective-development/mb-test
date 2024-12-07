# frozen_string_literal: true

module Shared
  module Helpers
    # OrderAdjustment helper methods
    module OrderAdjustmentHelper
      require 'data_cleaners'

      def permitted_order_adjustment_params(params, user)
        ActionController::Parameters.new(params[:order_adjustment])
                                    .permit(:reason_id, :description, :credit, :financial, :amount)
                                    .merge(user_id: user.id, braintree: true, amount: DataCleaners::Parser::Price.parse(params[:order_adjustment][:amount]))
      end
    end
  end
end
