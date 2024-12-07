# == Schema Information
#
# Table name: employees
#
#  id          :integer          not null, primary key
#  supplier_id :integer
#  user_id     :integer
#  active      :boolean          default(FALSE), not null
#  created_at  :datetime
#  updated_at  :datetime
#  sms         :boolean          default(FALSE), not null
#  voice       :boolean          default(FALSE), not null
#  phone       :string(255)
#  send_email  :boolean          default(TRUE), not null
#
# Indexes
#
#  index_employees_on_supplier_id_and_user_id  (supplier_id,user_id)
#  index_employees_on_user_id                  (user_id)
#

class Employee < ActiveRecord::Base
  has_paper_trail ignore: %i[created_at updated_at]

  belongs_to :supplier, touch: true
  belongs_to :user
  has_one :account, through: :user, source_type: 'RegisteredAccount'

  delegate :first_name, to: :account
  delegate :last_name,  to: :account
  delegate :email,      to: :account
  delegate :name,       to: :account
  delegate :driver?,    to: :user
  delegate :supplier?,  to: :user
  delegate :roles,      to: :user

  scope :active,    -> { where(active: true) }
  scope :inactive,  -> { where(active: false) }
  scope :excluding_minibar_employees, -> { joins(:account).where.not("registered_accounts.email like '%minibardelivery.com'") }

  phony_normalize :phone, default_country_code: 'US'

  before_destroy :remove_supplier_role

  def activate!
    update_attribute(:active, true) unless active?
  end

  def deactivate!
    update_attribute(:active, false) if active?
  end

  private

  def remove_supplier_role
    user.roles.delete(:supplier) && user.save if user.present?
    true
  end
end
