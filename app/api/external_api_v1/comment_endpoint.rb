# frozen_string_literal: true

class ExternalAPIV1
  # ExternalAPIV1::CommentEndpoint
  class CommentEndpoint < ExternalAPIV1
    helpers Shared::Helpers::CommentHelper, Shared::Helpers::CommentParamHelper

    resource :comments do
      after_validation do
        find_commentable(params)
      end

      params do
        use :comment_params

        optional :order_number, type: String, desc: 'Order Number', allow_blank: false
        optional :shipment_uuid, type: String, desc: 'Shipment UUID', allow_blank: false

        exactly_one_of :order_number, :shipment_uuid
      end

      desc 'Creates a new comment for a given commentable'
      post do
        @comment = @commentable.comments.new(permitted_comment_params(params, current_user, @commentable.user))

        if params[:comment][:file].present?
          file = Paperclip.io_adapters.for(params[:comment][:file][:tempfile])
          file.original_filename = params[:comment][:file][:filename]

          @comment.file = file
        end

        if @comment.save
          status 201
          present @comment, with: Shared::Entities::Comment
        else
          error!(@comment.errors, 422)
        end
      end
    end
  end
end
