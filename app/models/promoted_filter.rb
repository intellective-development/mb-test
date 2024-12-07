# == Schema Information
#
# Table name: promoted_filters
#
#  id                     :integer          not null, primary key
#  product_type_id        :integer
#  facet_promoted_filters :json
#  highlighted_filters    :json
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_promoted_filters_on_product_type_id  (product_type_id)
#
# Foreign Keys
#
#  fk_rails_...  (product_type_id => product_types.id)
#

class PromotedFilter < ActiveRecord::Base
  belongs_to :product_type

  validates :product_type_id, presence: true

  def self.admin_grid(params = {})
    grid = PromotedFilter.order(:product_type_id, :id)
    grid = grid.joins(:product_type)
    grid = grid.where('lower(product_types.name) LIKE ?', "%#{params[:name].downcase}%") if params[:name].present?
    grid
  end
end
