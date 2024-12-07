# frozen_string_literal: true

# TODO: Consider behaviors when the :recommended param is true - should we be suppressing certain categories
# (e.g. mixers, bartenders.) Also, should we be favoring a relevance vs popularity given sort.s

class MissingQueryError < StandardError
  def to_s
    'Failed to autocomplete: missing query'
  end
end

class MissingParamsError < StandardError
  def to_s
    'Failed to autocomplete: missing params'
  end
end

class MissingSuppliersError < StandardError
  def to_s
    'Failed to autocomplete: missing supplier_ids in params'
  end
end

class ProductGroupingSearch::Autocomplete < ProductGroupingSearch::Base
  def initialize(query, supplier_ids, params)
    raise MissingQueryError if query.blank?
    raise MissingParamsError if params.blank?
    raise MissingSuppliersError if supplier_ids.blank?

    @params = params
    @supplier_ids = supplier_ids

    super(query)
  end

  def search_options
    @params.except(:track)
  end
end
