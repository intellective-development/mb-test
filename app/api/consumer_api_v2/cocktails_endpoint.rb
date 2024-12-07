class ConsumerAPIV2::CocktailsEndpoint < BaseAPIV2
  helpers Shared::Helpers::BrowseParamHelpers
  namespace :cocktails do
    get do
      filters = {}
      filters[:tags] = params[:tag] if params[:tag].present?
      filters[:tags] = params[:tags] if params[:tags].present?
      page = params[:page].presence || 1
      per_page = params[:per_page].presence || 10
      @all_matches = Cocktail.search params[:search].presence || '*', where: filters
      @page = Kaminari.paginate_array(@all_matches).page(page).per(per_page)
      present :data, @page, with: Shared::Entities::Cocktails::Cocktail
      present :count, @all_matches.count
      present :page, page
      present :per_page, per_page
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

      desc 'Get cocktail\'s bundle if any'
      resource :bundle do
        get do
          bundle_service = BundleService.new(nil, nil, storefront.business, params, request.headers['Authorization'], @cocktail.id)
          suggestions = bundle_service.find_bundle_options

          present bundle_service.bundle, with: ConsumerAPIV2::Entities::Bundle, suggestions: suggestions
        end
      end
    end
  end
end
