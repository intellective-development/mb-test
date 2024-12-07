# == Schema Information
#
# Table name: product_groupings
#
#  id                    :integer          not null, primary key
#  featured              :boolean          default(FALSE), not null
#  searchable            :boolean          default(TRUE), not null
#  state                 :string(255)      default("active")
#  brand_id              :integer
#  product_content_id    :integer
#  hierarchy_category_id :integer
#  hierarchy_subtype_id  :integer
#  hierarchy_type_id     :integer
#  product_type_id       :integer
#  meta_description      :string(255)
#  meta_keywords         :string(255)
#  name                  :string(255)      not null
#  permalink             :string(255)
#  description           :text
#  keywords              :text
#  created_at            :datetime
#  updated_at            :datetime
#  tax_category_id       :integer
#  trimmed_name          :string
#  gift_card_theme_id    :integer
#  default_search_hidden :boolean          default(FALSE)
#  business_remitted     :boolean          default(FALSE)
#  master                :boolean          default(FALSE)
#  liquid_id             :string
#
# Indexes
#
#  index_product_groupings_on_brand_id               (brand_id)
#  index_product_groupings_on_gift_card_theme_id     (gift_card_theme_id)
#  index_product_groupings_on_hierarchy_category_id  (hierarchy_category_id)
#  index_product_groupings_on_hierarchy_subtype_id   (hierarchy_subtype_id)
#  index_product_groupings_on_hierarchy_type_id      (hierarchy_type_id)
#  index_product_groupings_on_liquid_id              (liquid_id) UNIQUE
#  index_product_groupings_on_name                   (name)
#  index_product_groupings_on_permalink              (permalink) UNIQUE
#  index_product_groupings_on_product_content_id     (product_content_id)
#  index_product_groupings_on_product_type_id        (product_type_id)
#
# Foreign Keys
#
#  fk_rails_...  (gift_card_theme_id => gift_card_themes.id)
#

class ProductGrouping < ProductSizeGrouping
  # This is an empty class used as a shim for compatibility with the Brand Admin app.
  # the ProductUpdateJob will attempt to unpack global_ids using this class.
end
