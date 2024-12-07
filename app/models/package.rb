# == Schema Information
#
# Table name: packages
#
#  id                     :integer          not null, primary key
#  carrier                :string(40)
#  shipment_id            :integer
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  label_url              :string
#  uuid                   :uuid
#  tracking_number        :string
#  tracking_url           :string
#  state                  :string(255)      default("pending"), not null
#  expected_delivery_date :date
#  carrier_tracking_url   :string
#
# Indexes
#
#  index_packages_on_shipment_id      (shipment_id)
#  index_packages_on_state            (state)
#  index_packages_on_tracking_number  (tracking_number) UNIQUE
#  index_packages_on_uuid             (uuid) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (shipment_id => shipments.id)
#

class Package < ActiveRecord::Base
  include Statesman::Adapters::ActiveRecordQueries
  include MachineAdapter
  include Iterable::Storefront::Serializers::PackageSerializer

  belongs_to :shipment, optional: false

  has_one :after_ship_tracking, dependent: :destroy
  has_one :ship_engine_detail, dependent: :destroy
  has_one :package_custom_detail, class_name: 'Package::CustomDetail', dependent: :destroy, autosave: true

  has_many :package_transitions, dependent: :destroy, autosave: false
  has_one :last_package_transition, -> { where(most_recent: true) }, class_name: 'PackageTransition'

  statesman_machine machine_class: Package::StateMachine, transition_class: PackageTransition

  RB_TRACKING_PAGE_BASE_URL = 'https://tracking.reservebar.com'.freeze

  validates :tracking_number, uniqueness: true, allow_nil: true

  delegate :order, to: :shipment
  delegate :supplier, to: :shipment

  def carrier=(value)
    super(value&.downcase)
  end

  def tracking_number=(value)
    super(value&.strip)
  end

  def shipping_date
    package_transitions.find_by(to_state: :en_route)&.created_at&.strftime('%B %d %Y %H:%M %P (%Z)')
  end
end
