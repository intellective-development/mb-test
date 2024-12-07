# == Schema Information
#
# Table name: product_grouping_changesets
#
#  id                  :integer          not null, primary key
#  product_grouping_id :integer
#  changeset           :text
#  message             :text
#  account_id          :integer
#  created_at          :datetime
#  updated_at          :datetime
#  duplicate_id        :integer
#

class ProductGroupingChangeset < ActiveRecord::Base
  serialize :changeset

  belongs_to :product_grouping
  belongs_to :duplicate_of_product_grouping, class_name: 'ProductGrouping', foreign_key: 'duplicate_id'
  has_one :brand, through: :product_grouping

  belongs_to :account, class_name: 'RegisteredAccount'
  has_one :user, through: :account

  validates :product_grouping, :account, presence: true

  delegate :trigger, :trigger!, :current_state, to: :state_machine

  def current_metadata
    set = {}
    changes = changeset['product_grouping']
    if changes
      changes.drop(1).each do |k, v|
        set[k] = v[0] unless k == 'properties'
      end
      set
    else
      changes
    end
  end

  def current_properties
    set = {}
    changes = changeset['product_grouping']
    if changes
      changes.drop(1).each do |k, v|
        next unless k == 'properties'

        v[0].each do |name, value|
          set[name] = value
        end
      end
      set
    else
      changes
    end
  end

  def new_metadata
    set = {}
    changes = changeset['product_grouping']
    if changes
      changes.drop(1).each do |k, v|
        set[k] = v[1] unless k == 'properties'
      end
      set
    else
      changes
    end
  end

  def new_properties
    set = {}
    changes = changeset['product_grouping']
    if changes
      changes.drop(1).each do |k, v|
        next unless k == 'properties'

        v[1].each do |name, value|
          set[name] = value
        end
      end
      set
    else
      changes
    end
  end

  def metadata_changes
    require 'hashdiff'
    Hashdiff.diff(current_metadata, new_metadata)
  end

  def property_changes
    require 'hashdiff'
    Hashdiff.diff(current_properties, new_properties)
  end

  def state_machine
    @state_machine ||= ChangesetStateMachine.new(self)
  end

  def self.initial_state
    :submitted
  end
  private_class_method :initial_state

  class ChangesetStateMachine
    include Statesman::Machine
    include Statesman::Events

    state :submitted, initial: true
    state :accepted
    state :rejected
    state :cancelled

    event :accept do
      transition from: :submitted, to: :accepted
    end

    event :reject do
      transition from: :submitted, to: :rejected
    end

    event :cancel do
      transition from: :submitted, to: :cancelled
    end

    before_transition(from: :submitted, to: :accepted) do |changeset, transition, metadata|
      # Do something to merge the changes
      # If this is a duplicate, you can get the original through the association duplicate_of_product_grouping
    end

    after_transition(from: :submitted) do |changeset, _transition, _metadata|
      changeset.destroy
    end

    after_transition(to: %i[accepted rejected]) do |changeset, transition, metadata|
      payload = JiffyBag.encode(
        product_grouping_id: changeset.product_grouping_id,
        state: transition.to_state,
        message: Hash(metadata).fetch(:message, nil)
      )

      Sidekiq::Client.push(
        'class' => 'ChangesetResponseJob',
        'queue' => 'brand_admin_default',
        'args' => Array(payload)
      )
    end
  end
end
