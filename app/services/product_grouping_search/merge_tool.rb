class ProductGroupingSearch::MergeTool < ProductGroupingSearch::Base
  SEARCH_FIELDS = [:name].freeze

  def initialize(params)
    # Rails 5.2 does not inherit from Hash anymore
    # TODO: refactor this to not work with params, work with well
    #       described arguments instead.
    @params = if params.instance_of?(ActionController::Parameters)
                params.to_unsafe_h.deep_symbolize_keys.dup.freeze
              else
                params.symbolize_keys.dup.freeze
              end
    @supplier_ids = Array(params[:supplier_id])

    super(@params[:term].presence || WILDCARD_QUERY)
  end

  def search_options
    {
      where: get_filters,
      limit: @params[:limit] || 100,
      fields: SEARCH_FIELDS,
      load: false
    }
  end

  def nested_matches
    if @params[:out_of_stock] == true
      []
    else
      [
        { range: { 'variants.in_stock' => { gte: 1 } } }
      ]
    end
  end

  private

  # SEARCH COMPONENTS
  def get_filters
    {
      state: { not: 'merged' }
    }
  end
end
