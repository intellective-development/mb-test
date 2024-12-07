module ListOrganizer
  extend ActiveSupport::Concern

  included do
    include ::HasScope

    has_scope :pagination, using: %i[page per_page], type: :hash do |_controller, scope, value|
      scope.page(value[0]).per(value[1])
    end

    has_scope :by_sort, using: %i[sort direction], type: :hash do |_controller, scope, value|
      scope.order(value[0] => value[1])
    end
  end

  class_methods do
    attr_reader :sort_columns

    def sortable(columns)
      @sort_columns = columns
    end
  end

  attr_reader :params

  def initialize(params)
    @params = params || {}
  end

  def sort_column
    self.class.sort_columns.include?(params[:sort]) ? params[:sort] : 'id'
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : 'asc'
  end

  protected

  def list_params
    page_attr(add_sort_attributes(params))
  end

  def add_sort_attributes(params)
    params.merge(by_sort: { sort: sort_column, direction: sort_direction })
  end

  def page_attr(params)
    params.merge(pagination: { page: pagination_page, per_page: pagination_per_page })
  end

  def pagination_page
    params[:page].present? ? params[:page].to_i : 1
  end

  def pagination_per_page
    25
  end
end
