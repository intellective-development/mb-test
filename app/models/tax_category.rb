# == Schema Information
#
# Table name: tax_categories
#
#  id          :integer          not null, primary key
#  name        :string(255)      not null
#  description :string(255)
#  purpose     :integer          default("product")
#

class TaxCategory < ActiveRecord::Base
  has_paper_trail

  enum purpose: { product: 0, shipping: 1 }

  has_many :products
  has_many :tax_rates

  validates :name, presence: true
end
