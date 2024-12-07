class ProductGroupingSearch::FiltersResults < Searchkick::Results
  def initialize(results)
    super(results.klass, results.response, results.options)
  end

  def aggs=(aggregations)
    response['aggregations'] = aggregations
  end
end
