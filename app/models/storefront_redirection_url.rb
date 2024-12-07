# frozen_string_literal: true

# == Schema Information
#
# Table name: storefront_redirection_urls
#
#  id            :integer          not null, primary key
#  storefront_id :integer
#  order_id      :integer
#  name          :string           not null
#  value         :string           not null
#
# Indexes
#
#  index_storefront_redirection_urls_on_order_id       (order_id)
#  index_storefront_redirection_urls_on_storefront_id  (storefront_id)
#
class StorefrontRedirectionUrl < ActiveRecord::Base
  belongs_to :storefront
  belongs_to :order

  validates :value, :name, presence: true

  def build_url
    protected_environment? ? "#{value}&web_lockup_codeword=mini1234" : value
  end

  private

  def protected_environment?
    %w[development sandbox staging].include?(ENV['ENV_NAME'])
  end
end
