# == Schema Information
#
# Table name: invoicing_recipients
#
#  id          :integer          not null, primary key
#  description :string(255)
#  supplier_id :integer
#  created_at  :datetime
#  updated_at  :datetime
#  email       :text
#
# Indexes
#
#  index_invoicing_recipients_on_supplier_id  (supplier_id)
#

class InvoicingRecipient < ActiveRecord::Base
  belongs_to :supplier

  def create_invoice(business_id, begin_date, end_date)
    SupplierInvoice.where(
      sender_id: nil,
      recipient_id: id,
      currency: 'USD',
      period_start: begin_date,
      period_end: end_date,
      business_id: business_id
    ).where.not(status: 'voided').first_or_create
  end
end
