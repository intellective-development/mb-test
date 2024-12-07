# frozen_string_literal: true

module Shared
  module Helpers
    # Shared::Helpers::CommentParamHelper
    module CommentParamHelper
      extend Grape::API::Helpers

      params :comment_params do
        requires :comment, type: Hash do
          requires :note, type: String, desc: 'Note', allow_blank: false
          optional :file, type: File, desc: 'File'
        end
      end
    end
  end
end
