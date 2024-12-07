# == Schema Information
#
# Table name: cocktails
#
#  id           :integer          not null, primary key
#  name         :text
#  permalink    :text
#  description  :text
#  serves       :text
#  brand_id     :integer
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  tags         :text             default([]), is an Array
#  instructions :text             default([]), is an Array
#  active       :boolean          default(FALSE)
#  deleted_at   :datetime
#

class Cocktail < ActiveRecord::Base
  include FriendlyId
  include CreateUuid

  acts_as_taggable
  acts_as_paranoid

  belongs_to :brand
  has_many :ingredients, -> { order(:created_at) }, dependent: :destroy
  has_many :images, -> { order(:position) }, as: :imageable, dependent: :destroy
  has_one :thumbnail, class_name: 'Asset', as: :owner, dependent: :destroy

  has_many :related_cocktails_association, class_name: 'RelatedCocktail'
  has_many :related_cocktails, through: :related_cocktails_association, source: :related_cocktail

  has_many :cocktail_tools
  has_many :tools, through: :cocktail_tools

  friendly_id :permalink_candidates, use: %i[slugged finders history], slug_column: :permalink
  # This is required due to the following issues in friendly_id 5.2.0
  # https://github.com/norman/friendly_id/issues/765
  alias_attribute :slug, :permalink

  def permalink_candidates
    [
      [:name],
      [:name, '-', :uuid]
    ]
  end

  searchkick callbacks: :async,
             index_name: -> { "#{name.tableize}_#{ENV['SEARCHKICK_SUFFIX'] || ENV['RAILS_ENV']}" },
             batch_size: 200

  def search_data
    attributes.merge(
      'tags' => tag_list
    )
  end

  scope :search_import, -> { where(active: true) }

  def should_index?
    active # only index active records
  end

  def self.admin_grid(params = {}, _active_state = nil)
    name_filter(params[:name])
  end

  def self.name_filter(name)
    name.present? ? where('lower(cocktails.name) LIKE lower(?)', "%#{name}%") : all
  end
end
