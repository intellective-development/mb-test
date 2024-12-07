class AdminAPIV1::CocktailsEndpoint < BaseAPIV1
  namespace :cocktails do
    get do
      present Cocktail.includes(:ingredients, :thumbnail, :related_cocktails, :brand, :taggings, :images, tools: [:icon]).all,
              with: Shared::Entities::Cocktails::Cocktail
    end

    get :search do
      present Cocktail.admin_grid(name: params[:query]), with: Shared::Entities::Cocktails::Cocktail
    end

    desc 'Create a cocktail'
    params do
      requires :name
      requires :description
    end
    post do
      @cocktail = Cocktail.new(cocktail_from_params(params))
      @cocktail = compose_cocktail
      present :permalink, @cocktail.permalink
    end

    route_param :cocktail_permalink do
      before do
        @cocktail = Cocktail.find_by(permalink: params[:cocktail_permalink])
        error!('Cocktail not found', 404) if @cocktail.nil?
      end

      desc 'get cocktail by id'
      get do
        present @cocktail, with: Shared::Entities::Cocktails::Cocktail
      end

      desc 'update cocktail by id'
      put do
        @cocktail = compose_cocktail
        present :permalink, @cocktail.permalink
      end
    end
  end

  namespace :tools do
    get do
      present Tool.all, with: Shared::Entities::Tools::Tool
    end

    get :search do
      present Tool.admin_grid(name: params[:query]), with: Shared::Entities::Tools::Tool
    end

    desc 'Create a tool'
    params do
      requires :name
      requires :description
    end
    post do
      @tool = Tool.new(tool_from_params(params))
      @tool = compose_tool
      present :id, @tool.id
    rescue StandardError => e
      Rails.logger.error(e.message)
    end

    route_param :cocktail_id do
      before do
        @tool = Tool.find_by(id: params[:cocktail_id])
        error!('Tool not found', 404) if @tool.nil?
      end

      desc 'get tool by id'
      get do
        present @tool, with: Shared::Entities::Tools::Tool
      end

      desc 'update tool by id'
      put do
        @tool = compose_tool
        present :id, @tool.id
      end
    end
  end

  helpers do
    def compose_cocktail
      @cocktail.name = params[:name]
      @cocktail.description = params[:description]
      @cocktail.active = params[:active]
      @cocktail.serves = params[:serves]
      @cocktail.thumbnail = compose_asset(params[:thumbnail])
      @cocktail.related_cocktails = related_cocktails_from_params(params) || []
      @cocktail.ingredients = ingredients_from_params(params) || []
      @cocktail.tag_list = params[:tags] ? params[:tags].map { |_index, tag| tag } : ''
      @cocktail.instructions = params[:instructions] ? params[:instructions].map { |_index, instruction| instruction } : []
      @cocktail.tools = tools_from_params(params) || []
      @cocktail.images = images_params(params) || []
      @cocktail.brand = brand_from_params(params)
      @cocktail.save
      @cocktail
    end

    def set_image(url)
      images.create(photo_from_link: url)
    rescue StandardError => e
      Rails.logger.error "Error setting image '#{url}' to Grouping #{id}: #{e}"
      raise
    end

    def images_params(params)
      imgs_array = []
      if params[:images].present? && params[:images].map
        params[:images].map do |_key, image|
          image = compose_image(image)
          imgs_array.push image if image
        end
      end
      imgs_array
    end

    def compose_image(image)
      if image.is_a?(Hash)
        if image[:id]
          Image.find_by(id: image['id'])
        elsif image[:photo_from_link].present?
          Image.new(photo_from_link: image[:photo_from_link])
        elsif image[:tempfile].present?
          file_from_hash = ActionDispatch::Http::UploadedFile.new(image)
          Image.new(photo: file_from_hash)
        end
      end
    end

    def ingredients_from_params(params)
      ingredients = remove_empty_values(params[:ingredients])
      if ingredients.present?
        ingredients.map do |_key, ingredient|
          ingredient[:name] ||= ''
          ingredient[:qty] ||= ''
          ingredient[:product] ||= ''
          if ingredient[:id]
            @ingredient = Ingredient.find_by(id: ingredient[:id])
            @ingredient.assign_attributes ingredient
            # TODO: why doesn't it save nested? Let it be transactional
            @ingredient.save
            @ingredient
          else
            Ingredient.new(ingredient)
          end
        end
      end
    end

    def tools_from_params(params)
      tools = remove_empty_values(params[:tools])
      if tools.present?
        tools.map do |_key, tool|
          Tool.find_by(id: tool[:id])
        end
      end
    end

    def brand_from_params(params)
      Brand.find_by(id: params[:brand][:id]) if params[:brand].is_a?(Hash)
    end

    def related_cocktails_from_params(params)
      related_cocktails = remove_empty_values(params[:related_cocktails])
      if related_cocktails.present?
        related_cocktails.map do |_key, cocktail|
          Cocktail.find_by(id: cocktail[:id])
        end
      end
    end

    def cocktail_from_params(params)
      params.except(:cocktail_id, :ingredients, :tools, :brand, :images, :related_cocktails, :tags, :thumbnail)
    end

    def compose_tool
      @tool.name = params[:name]
      @tool.description = params[:description]
      @tool.icon = compose_asset(params[:icon])
      @tool.save
      @tool
    end

    def compose_asset(asset)
      if asset.is_a?(Hash)
        if asset[:id]
          Asset.find_by(id: asset['id'])
        elsif asset[:tempfile].present?
          file_from_hash = ActionDispatch::Http::UploadedFile.new(asset)
          Asset.new(file: file_from_hash)
        end
      end
    end

    def tool_from_params(params)
      params.except(:images, :icon)
    end

    def remove_empty_values(hash)
      hash&.delete_if { |_k, v| v.nil? }
    end
  end
end
