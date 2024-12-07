# == Schema Information
#
# Table name: delivery_estimates
#
#  id          :integer          not null, primary key
#  description :string(255)
#  created_at  :datetime
#  updated_at  :datetime
#  minimum     :integer
#  maximum     :integer
#  active      :boolean          default(TRUE), not null
#

class DeliveryEstimate < ActiveRecord::Base
  has_one :shipment

  scope :active, -> { where(active: true) }

  def description
    self[:description] || generate_description
  end

  def can_calculate_lateness?
    !minimum.nil? && !maximum.nil?
  end

  def under_half?
    maximum <= 30
  end

  def under_hour?
    maximum <= 60
  end

  def user_description
    return unless can_calculate_lateness?
    return 'under 45 minutes' if under_half?
    return 'under 60 minutes' if under_hour?

    description
  end

  private

  def generate_description
    return nil unless maximum && minimum

    # TODO: Extract string generation into a service and handle more dynamic cases
    # such as expressing time in hours/days as appropriate.
    "#{minimum}-#{maximum} minutes"
  end
end
