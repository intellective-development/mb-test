class Admin::Merchandise::PromotedFiltersController < Admin::BaseController
  helper_method :sort_column, :sort_direction
  respond_to :html, :json

  FACET_FILTERS_OPTIONS = [
    { id: 'country', name: 'Country' },
    { id: 'container_type', name: 'Container Type' },
    { id: 'hierarchy_subtype', name: 'Hierarchy Subtype' },
    { id: 'hierarchy_type', name: 'Hierarchy Type' },
    { id: 'brand', name: 'Brand' },
    { id: 'volume', name: 'Volume' }
  ].freeze

  def index
    @promoted_filters = PromotedFilter.admin_grid(params)
                                      .order("#{sort_column} #{sort_direction}")
                                      .page(pagination_page)
                                      .per(pagination_rows)
  end

  def new
    @promoted_filter = PromotedFilter.new
    load_form_data
  end

  def create
    unless params['promoted_filter']['product_type_id'].present?
      flash[:error] = 'You need to select a category.'
      render action: :new
    end
    if PromotedFilter.exists?(product_type_id: params[:hierarchy_category])
      flash[:error] = 'A filter for this category already exists.'
      render action: :new
    end
    # set values to the model to save
    @promoted_filter = PromotedFilter.new
    @promoted_filter.highlighted_filters = []
    @promoted_filter.facet_promoted_filters = {}
    @promoted_filter.product_type_id = params['promoted_filter']['product_type_id']
    if @promoted_filter.save
      redirect_to action: :index
    else
      flash[:error] = 'The promoted filter could not be saved'
      render action: :new
    end
  end

  def edit
    @promoted_filter = PromotedFilter.find(params[:id])
    if @promoted_filter.facet_promoted_filters['brand']
      brands = Brand.where(permalink: @promoted_filter.facet_promoted_filters['brand'])
      @promoted_filter.facet_promoted_filters['brand'] = brands&.map(&:id)
    end
    @promoted_filter.highlighted_filters.map do |hf|
      if hf['name'] == 'brand'
        brand = Brand.find_by(permalink: hf['term'])
        hf['term'] = brand&.id
      end
      hf
    end
    load_form_data
  end

  def update
    @promoted_filter = PromotedFilter.find(params[:id])

    # parse highlighted filters values
    highlighted_filters_hash = params.select { |key, _value| key.to_s.match(/^highlighted_filter_\d+/) }
    highlighted_filters = parse_highlighted_filters(highlighted_filters_hash.values)

    # parse facet filters values
    facet_filters = parse_facet_filters(params['facet_filter'])

    # set values to the model to save
    @promoted_filter.highlighted_filters = highlighted_filters
    @promoted_filter.facet_promoted_filters = facet_filters
    @promoted_filter.product_type_id = params['promoted_filter']['product_type_id']
    if @promoted_filter.update(allowed_params)
      redirect_to action: :index
    else
      render action: :edit
    end
  end

  def add_facet_filter
    @promoted_filter = PromotedFilter.find(params[:id])
    facet_filter = parse_facet_filters(params['facet_filter'])

    @promoted_filter.facet_promoted_filters.merge!(facet_filter)
    Rails.logger.error @promoted_filter.errors.full_messages unless @promoted_filter.save
    redirect_to edit_admin_merchandise_promoted_filter_path(@promoted_filter)
  end

  def remove_facet_filter
    @promoted_filter = PromotedFilter.find(params[:id])
    facet_filter_key = params['facet_key']

    unless @promoted_filter.facet_promoted_filters.keys.include?(facet_filter_key)
      Rails.logger.error "Filter key does not exists: #{facet_filter_key}"
      redirect_to edit_admin_merchandise_promoted_filter_path(@promoted_filter)
    end

    @promoted_filter.facet_promoted_filters.delete(facet_filter_key)
    Rails.logger.error @promoted_filter.errors.full_messages unless @promoted_filter.save
    redirect_to edit_admin_merchandise_promoted_filter_path(@promoted_filter)
  end

  def add_highlighted_filter
    @promoted_filter = PromotedFilter.find(params[:id])

    highlighted_filters_hash = params.select { |key, _value| key.to_s.match(/^highlighted_filter_\d+/) }
    highlighted_filter = parse_highlighted_filters(highlighted_filters_hash.values)[0]

    unless highlighted_filter[:name].present? && highlighted_filter[:description].present? && highlighted_filter[:term].present?
      flash[:error] = 'Name, description and term are mandatory.'
      redirect_to edit_admin_merchandise_promoted_filter_path(@promoted_filter)
    end

    @promoted_filter.highlighted_filters << highlighted_filter
    unless @promoted_filter.save
      Rails.logger.error @promoted_filter.errors.full_messages
      # render action: :edit, id: @promoted_filter.id
    end
    redirect_to edit_admin_merchandise_promoted_filter_path(@promoted_filter)
  end

  def remove_highlighted_filter
    @promoted_filter = PromotedFilter.find(params[:id])
    index = params['index'].to_i if params['index'].present?

    if @promoted_filter.highlighted_filters.size >= index
      Rails.logger.error "Index does not exist: #{index} - #{@promoted_filter.highlighted_filters.size}"
      redirect_to edit_admin_merchandise_promoted_filter_path(@promoted_filter)
    end

    @promoted_filter.highlighted_filters.delete_at(index)
    Rails.logger.error @promoted_filter.errors.full_messages unless @promoted_filter.save
    redirect_to edit_admin_merchandise_promoted_filter_path(@promoted_filter)
  end

  private

  def load_form_data
    @categories = ProductType.active.where('parent_id is null')
    category_ids = @categories.map(&:id)
    @hierarchy_types = ProductType.active.where("parent_id in (#{category_ids.join(', ')})")
    type_ids = category_ids = @hierarchy_types.map(&:id)
    @hierarchy_subtypes = ProductType.active.where("parent_id in (#{type_ids.join(', ')})")
    @facet_filters_options = FACET_FILTERS_OPTIONS
  end

  def parse_facet_filters(facet_filters)
    key_filters_hash = facet_filters.select { |key, _value| key.to_s.match(/^key_\d+/) }
    parsed_data = {}
    (0..key_filters_hash.values.size - 1).step(1) do |index|
      filter_key = facet_filters["key_#{index}"]
      filter_value = facet_filters["term_#{index}"]&.split(', ')
      if filter_key == 'brand'
        brands = Brand.where(id: facet_filters["brand_#{index}"])
        filter_value = brands&.map(&:permalink)
      end

      filter_value = facet_filters["hierarchy_type_#{index}"] if filter_key == 'hierarchy_type'
      filter_value = facet_filters["hierarchy_subtype_#{index}"] if filter_key == 'hierarchy_subtype'
      filter_value.reject!(&:empty?)
      parsed_data[filter_key] = filter_value
    end
    parsed_data
  end

  def parse_highlighted_filters(highlighted_filters)
    highlighted_filters.map do |hf|
      if hf['name'] == 'brand'
        brand = Brand.find(hf['brand'])
        hf['term'] = brand&.permalink
      end
      hf['term'] = hf['hierarchy_type'] if hf['name'] == 'hierarchy_type'
      hf['term'] = hf['hierarchy_subtype'] if hf['name'] == 'hierarchy_subtype'

      hf.extract!('name', 'description', 'term')
    end
  end

  def allowed_params
    params.require(:promoted_filter).permit(:id, :product_type_id, :facet_promoted_filters, :highlighted_filters)
  end

  def sort_column
    PromotedFilter.column_names.include?(params[:sort]) ? params[:sort] : 'product_type_id'
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : 'asc'
  end
end
