# frozen_string_literal: true

# == Schema Information
#
# Table name: storefront_webhooks
#
#  id            :bigint(8)        not null, primary key
#  url           :string
#  header        :string
#  secret        :string
#  enabled       :boolean
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  storefront_id :bigint(8)        not null
#
# Indexes
#
#  index_storefront_webhooks_on_storefront_id  (storefront_id)
#
# Foreign Keys
#
#  fk_rails_...  (storefront_id => storefronts.id)
#
class StorefrontWebhook < ApplicationRecord
  include SentryNotifiable

  belongs_to :storefront
end
