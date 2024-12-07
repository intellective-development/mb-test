# frozen_string_literal: true

# == Schema Information
#
# Table name: supplier_types
#
#  id          :integer          not null, primary key
#  name        :text
#  description :text
#  created_at  :datetime
#  updated_at  :datetime
#  exclusive   :boolean          default(TRUE)
#  routable    :boolean          default(FALSE)
#  deferrable  :boolean          default(FALSE), not null
#

class SupplierType < ActiveRecord::Base
  DTC_NAME = 'Vineyard Select'
  PROMO_NAME = 'Promotions'

  # Exclusive denotes supplier types whom we always want to only select
  # a single instance when routing.
  scope :exclusive, -> { where(exclusive: true) }

  # Routable denotes supplier types which we allow an address to be
  # routed. Non-routable types are dependant on the existance at least one
  # routable type, else customer will be notified that there are no
  # delivery options available.
  scope :routable, -> { where(routable: true) }

  # Deferrable denotes that this supplier can be loaded on-demand by the
  # client rather than being assigned during the routing process. This is
  # used for Vineyard Select where all suppliers are shown and their coverage
  # is determined by the users state.
  scope :deferrable, -> { where(deferrable: true) }

  has_many :suppliers

  def dtc?
    name == DTC_NAME
  end

  def promo?
    name == PROMO_NAME
  end
end
