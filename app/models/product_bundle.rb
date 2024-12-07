# frozen_string_literal: true

# == Schema Information
#
# Table name: product_bundles
#
#  id                     :string           not null, primary key
#  external_id            :string           not null
#  title                  :string
#  images                 :jsonb
#  component_product_data :jsonb
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_product_bundles_on_external_id  (external_id) UNIQUE
#
class ProductBundle < ActiveRecord::Base
  validates :external_id, uniqueness: true
  validates :external_id, presence: true
end
