# == Schema Information
#
# Table name: supplier_reports
#
#  id                :integer          not null, primary key
#  state             :string(255)      default("pending"), not null
#  report_type       :string(255)      not null
#  supplier_id       :integer          not null
#  employee_id       :integer
#  start_date        :date             not null
#  end_date          :date             not null
#  started_at        :datetime
#  completed_at      :datetime
#  file_file_name    :string(255)
#  file_content_type :string(255)
#  file_file_size    :integer
#  file_updated_at   :datetime
#  created_at        :datetime
#  updated_at        :datetime
#  open_orders       :boolean          default(FALSE)
#  shipping_only     :boolean          default(FALSE)
#  delivery_only     :boolean          default(FALSE)
#
# Indexes
#
#  index_supplier_reports_on_supplier_id  (supplier_id)
#

class SupplierReport < ActiveRecord::Base
  include WisperAdapter

  belongs_to :supplier

  has_attached_file :file, BASIC_PAPERCLIP_OPTIONS.merge(
    path: 'supplier_reports/:hash/report.csv',
    s3_permissions: :private,
    s3_headers: { 'Cache-Control' => 'max-age=315576000',
                  'Expires' => 10.years.from_now.httpdate,
                  'Content-Disposition' => 'attachment; filename=report.csv' }
  )

  validates :supplier,    presence: true
  validates :report_type, presence: true
  validates_attachment :file, content_type: { content_type: 'text/csv' }

  before_create :set_default_values
  after_create  :publish_supplier_report_created

  state_machine initial: :pending do
    state :processing
    state :completed
    state :failed

    event :start do
      transition to: :processing, from: :pending
    end

    event :complete do
      transition to: :completed, from: :processing
    end

    event :error do
      transition to: :failed, from: %i[processing pending]
    end

    after_transition to: :processing, do: :publish_supplier_report_processing
    after_transition to: :completed,  do: :publish_supplier_report_completed
    after_transition to: :failed,     do: :publish_supplier_report_failed

    before_transition to: :processing, do: :set_started_at
    before_transition to: %i[failed completed], do: :set_completed_at
  end

  #-----------------------------------
  # Class methods
  #-----------------------------------

  def self.report_types
    Dir['app/models/supplier_reports/*.rb'].each { |file| load file }
    SupplierReports.constants.select { |c| SupplierReports.const_get(c).is_a? Class }.map { |c| c.to_s.underscore.upcase }.sort
  end

  #-----------------------------------
  # Wisper events
  #-----------------------------------

  def publish_supplier_report_created
    broadcast_event(:created, prefix: true)
  end

  def publish_supplier_report_processing
    broadcast_event(:processing, prefix: true)
  end

  def publish_supplier_report_completed
    broadcast_event(:completed, prefix: true)
  end

  def publish_supplier_report_failed
    broadcast_event(:failed, prefix: true)
  end

  #-----------------------------------
  # Instance methods
  #-----------------------------------

  def set_default_values
    # If start/end date are not specified then we default to last 30 days
    self.start_date = 30.days.ago.to_date if start_date.nil?
    self.end_date   = Time.zone.today     if end_date.nil?
  end

  def set_started_at
    self.started_at = Time.zone.now
  end

  def set_completed_at
    self.completed_at = Time.zone.now
  end

  def generate_report
    SupplierReportService.new(id).generate
  rescue SupplierReportGenerationError => e
    error!
  end

  def report_url
    return nil unless completed?

    Rails.cache.fetch("supplier_report:#{id}:report_url:updated_at", expires_in: 12.hours) do
      file.expiring_url(60 * 60 * 12)
    end
  end
end
