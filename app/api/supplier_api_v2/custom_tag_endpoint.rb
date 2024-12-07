class SupplierAPIV2::CustomTagEndpoint < BaseAPIV2
  helpers do
    def load_custom_tag
      @custom_tag = current_supplier.custom_tags.find(params[:custom_tag_id])
    rescue ActiveRecord::RecordNotFound
      error!('Custom Tag not found', 404)
    end
  end

  namespace :custom_tags do
    get do
      present current_supplier.custom_tags, with: SupplierAPIV2::Entities::CustomTag
    end
  end

  namespace :custom_tag do
    params do
      requires :name,        type: String, allow_blank: false
      requires :color,       type: String, allow_blank: false
      optional :description, type: String
    end

    post do
      custom_tag = current_supplier.custom_tags.new(params)

      if custom_tag.save
        present custom_tag, with: SupplierAPIV2::Entities::CustomTag
      else
        error!(custom_tag.errors.full_messages.first, 400)
      end
    end

    route_param :custom_tag_id do
      params do
        requires :name,        type: String, allow_blank: false
        requires :color,       type: String, allow_blank: false
        optional :description, type: String
      end

      before do
        load_custom_tag
      end

      put do
        if @custom_tag.update(params.slice(:name, :color, :description))
          present @custom_tag, with: SupplierAPIV2::Entities::CustomTag
        else
          error!(@custom_tag.errors.full_messages.first, 400)
        end
      end

      delete do
        if @custom_tag.destroy
          status 200
          { message: 'Custom tag deleted!' }
        else
          error!('An error occurred while deleting the given custom tag', 422)
        end
      end
    end
  end
end
