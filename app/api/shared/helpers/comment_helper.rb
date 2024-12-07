# frozen_string_literal: true

module Shared
  module Helpers
    # Shared::Helpers::CommentHelper
    module CommentHelper
      def find_commentable(params)
        @commentable = if params[:shipment_uuid]
                         Shipment.find_by(uuid: params[:shipment_uuid])
                       elsif params[:order_number]
                         Order.find_by(number: params[:order_number])
                       end

        error!('Commentable not found', 404) if @commentable.nil?
      end

      def permitted_comment_params(params, created_by, user)
        ActionController::Parameters.new(params[:comment]).permit(:note).merge(created_by: created_by.id, user_id: user.id)
      end
    end
  end
end
