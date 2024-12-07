# == Schema Information
#
# Table name: shipment_metadata
#
#  id                            :integer          not null, primary key
#  shipment_id                   :integer
#  driver_id                     :integer
#  signed_by_name                :string(255)
#  created_at                    :datetime
#  updated_at                    :datetime
#  delivered_at                  :datetime
#  distance                      :float            default(0.0)
#  supplier_invoice_file_name    :string(255)
#  supplier_invoice_content_type :string(255)
#  supplier_invoice_file_size    :integer
#  supplier_invoice_updated_at   :datetime
#  delivery_estimate             :float
#  estimated_delivered_at        :datetime
#
# Indexes
#
#  index_shipment_metadata_on_driver_id    (driver_id)
#  index_shipment_metadata_on_shipment_id  (shipment_id)
#

class ShipmentMetadata < ActiveRecord::Base
  belongs_to :shipment
  belongs_to :driver, class_name: 'Employee'

  has_attached_file :supplier_invoice, BASIC_PAPERCLIP_OPTIONS.merge(
    path: 'shipments/:hash/minibar_invoice.pdf',
    keep_old_files: true,
    s3_permissions: :private,
    s3_headers: { 'Cache-Control' => 'max-age=315576000',
                  'Expires' => 10.years.from_now.httpdate }
  )

  validates_attachment :supplier_invoice, content_type: { content_type: 'application/pdf' }

  def delivery_estimate_in_minutes
    delivery_estimate ? delivery_estimate / 60 : nil
  end
end
