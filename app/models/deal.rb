# == Schema Information
#
# Table name: deals
#
#  id                     :uuid             not null, primary key
#  type                   :string(100)
#  description            :text
#  category               :string
#  starts_at              :datetime
#  ends_at                :datetime
#  quota                  :integer          default(1000)
#  quota_remaining        :integer          default(1000)
#  single_use             :boolean          default(FALSE)
#  user_id                :integer
#  subject_id             :integer
#  subject_type           :string
#  total_used             :integer          default(0)
#  sponsor_type           :string(64)       default("Internal")
#  sponsor_name           :string           default("Minibar")
#  applicable_order       :integer          default(0)
#  minimum_units          :integer          default(1)
#  minimum_shipment_value :decimal(10, 2)   default(0.0)
#  maximum_value          :decimal(10, 2)
#  percentage             :decimal(10, 2)
#  amount                 :decimal(10, 2)
#  discount_type          :string(100)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  sponsor_id             :integer
#  sponsor_key            :string
#  subject_key            :string
#
# Indexes
#
#  index_deals_on_subject_type_and_subject_id  (subject_type,subject_id)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#

class Deal < ActiveRecord::Base
  class Presenter < SimpleDelegator
    def human_type
      type.titleize
    end

    # TODO: Both long_title and short_title are great refactor candidates for the future!
    #       We may wish to wait and see how some of the deals requirements develop - likelihood
    #       is that we will switch to strings entered by the deal creator rather than continue
    #       to generate titles appropriate for all cases.
    def short_title
      case subject_type
      when 'Region', 'State'
        case type
        when 'FreeShipping'
          'Free Delivery'
        when 'MonetaryValue'
          "#{currency(amount)} off in #{subject_name}."
        when 'Percentage'
          "#{percentage} off in #{subject_name}."
        else
          "#{human_type} #{subject_relation} #{subject_name}."
        end
      when 'Supplier'
        case type
        when 'FreeShipping'
          'Free Delivery'
        when 'VolumeDiscount'
          title = if discount_type == 'Percentage'
                    "Save #{percentage} with purchase of #{minimum_units}+ qualified items."
                  else
                    "Save #{currency(amount)} with purchase of #{minimum_units}+ qualified items."
                  end

          title << " Minimum #{currency(minimum_shipment_value)}." if minimum_shipment_value.positive?
          title
        when 'TwoForOneDiscount'
          "Buy 1, Get 1 For #{currency(amount)}."
        else
          human_type
        end
      when 'Brand'
        case type
        when 'FreeShipping'
          'Free Delivery'
        when 'MonetaryValue'
          "#{currency(amount)} off"
        else
          human_type
        end
      else
        human_type
      end
    end

    def long_title
      case type
      when 'VolumeDiscount'
        title = if discount_type == 'Percentage'
                  "Save #{percentage} with purchase of #{minimum_units} or more qualifying items."
                else
                  "Save #{currency(amount)} with purchase of #{minimum_units} or more qualifying items."
                end

        title << " Minimum purchase #{currency(minimum_shipment_value)}." if minimum_shipment_value.positive?
        title
      when 'Percentage'
        case subject_type
        when 'Brand'
          "#{percentage} off #{subject_name} products."
        else
          "#{percentage} off."
        end
      when 'MonetaryValue'
        case subject_type
        when 'Brand'
          "#{currency(amount)} off #{subject_name} products."
        else
          "#{currency(amount)} off."
        end
      when 'FreeShipping'
        case subject_type
        when 'Brand'
          "Free delivery on #{ordinal_order} that #{applicable_order.to_i.zero? ? 'include' : 'includes'} #{subject_name} products."
        else
          "Free delivery on #{ordinal_order}."
        end
      when 'TwoForOneDiscount'
        "Buy 1, Get 1 For #{currency(amount)}."
      else
        "#{human_type} #{subject_relation} #{subject_name} for #{ordinal_order}."
      end
    end

    def percentage
      ActiveSupport::NumberHelper.number_to_percentage(super, strip_insignificant_zeros: true, precision: 2)
    end

    def currency(value)
      ActiveSupport::NumberHelper.number_to_currency(value)&.gsub(/\.00$/, '')
    end

    def ordinal_order
      return 'all orders' if applicable_order.to_i.zero?

      "your #{applicable_order.ordinalize} order"
    end

    def subject_relation
      case subject_type
      when 'State', 'Region'
        'in'
      when 'Supplier'
        'from'
      else
        'on'
      end
    end
  end

  belongs_to :user
  belongs_to :subject, polymorphic: true
  belongs_to :sponsor, polymorphic: true

  delegate :name, to: :subject, prefix: true

  before_validation :set_subject, if: :subject_attributes_changed?
  before_validation :set_sponsor, if: :sponsor_attributes_changed?

  validates :user, :subject, presence: true
  after_commit :update_es_data

  #----------------------------------------------------------------------
  # Scopes
  #----------------------------------------------------------------------
  scope :for_type_and_ids, ->(subject_type, subject_ids) { where(subject_type: subject_type, subject_id: subject_ids) }
  scope :for_types, ->(subject_types) { where(subject_type: subject_types) }
  scope :available_and_active, -> { where('quota > total_used AND starts_at <= now() AND ends_at >= now()') }

  ES_MAPPINGS = {
    type: 'nested',
    properties: {
      short_title: { type: 'keyword' },
      long_title: { type: 'keyword' },
      starts_at: { type: 'date' },
      ends_at: { type: 'date' }
    }
  }.freeze

  #----------------------------------------------------------------------
  # Instance Methods
  #----------------------------------------------------------------------
  def subject_attributes_changed?
    subject_type_changed? || subject_key_changed?
  end

  def sponsor_attributes_changed?
    sponsor_type_changed? || sponsor_key_changed?
  end

  def set_subject
    return unless subject_type && subject_key

    subject_class = subject_type.classify.constantize
    self.subject = subject_class.friendly.find(subject_key)
  end

  def set_sponsor
    return unless sponsor_type && sponsor_key

    sponsor_class_name = sponsor_type.classify
    return unless Object.const_defined?(sponsor_class_name)

    self.sponsor = sponsor_class_name.constantize.friendly.find(sponsor_key)
  end

  def deals_data
    presenter = Deal::Presenter.new(self)
    {
      short_title: presenter.short_title,
      long_title: presenter.long_title,
      type: type,
      starts_at: starts_at.strftime('%F'),
      ends_at: ends_at.strftime('%F')
    }
  end

  private

  def update_es_data
    DealReindexWorker.perform_async(subject_id, subject_type, type, persisted?)
  end
end

class MonetaryValue < Deal
end

class FreeShipping < Deal
end

class Percentage < Deal
end

class VolumeDiscount < Deal
end

class TwoForOneDiscount < Deal
end
