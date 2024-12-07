# == Schema Information
#
# Table name: supplier_notification_methods
#
#  id                :integer          not null, primary key
#  notification_type :integer          default("phone")
#  value             :string           not null
#  active            :boolean          default(TRUE), not null
#  supplier_id       :integer          not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  label             :string
#
# Indexes
#
#  index_supplier_notification_methods_on_notification_type  (notification_type)
#  index_supplier_notification_methods_on_supplier_id        (supplier_id)
#

class Supplier::NotificationMethod < ActiveRecord::Base
  auto_strip_attributes :value, squish: true

  has_paper_trail

  alias_attribute :phone_number, :value
  alias_attribute :email, :value

  enum notification_type: {
    phone: 0,
    sms: 1,
    email: 3
  }

  validates :notification_type, presence: true

  before_save :normalize_phone_number

  belongs_to :supplier

  scope :active,        -> { where(active: true) }
  scope :inactive,      -> { where(active: false) }

  def send_notification(shipment)
    case notification_type
    when 'phone' then Supplier::PhoneNotificationWorker.perform_async(id, shipment.id)
    when 'sms'   then Supplier::SmsNotificationWorker.perform_async(id, shipment.id)
    when 'email' then Supplier::EmailNotificationWorker.perform_async(id, shipment.id)
    end
  end

  def send_reminder(shipment, reminder_type = 'confirmation')
    case notification_type
    when 'phone' then Supplier::PhoneReminderWorker.perform_async(id, shipment.id, reminder_type)
    when 'sms'   then Supplier::SmsReminderWorker.perform_async(id, shipment.id, reminder_type)
    end
  end

  private

  def normalize_phone_number
    self.value = PhonyRails.normalize_number(value) if sms? || phone?
  end
end
