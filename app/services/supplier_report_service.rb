class SupplierReportGenerationError < StandardError; end

class SupplierReportService
  include SentryNotifiable

  require 'csv'

  def initialize(supplier_report_id)
    @supplier_report = SupplierReport.find(supplier_report_id)
    @report_type = @supplier_report.report_type.titleize.delete(' ')
    @report_class = "SupplierReports::#{@report_type}".constantize
    @report = nil
  rescue StandardError => e
    notify_sentry_and_log(e, e.message, { tags: { supplier_report_id: @supplier_report.id } })
    raise SupplierReportGenerationError
  end

  def format_value(value)
    case value
    when ActiveSupport::TimeWithZone
      value.in_time_zone(@supplier_report.supplier.timezone).strftime('%Y-%m-%d %I:%M%p') # 2020-02-02 02:20pm
    else
      value
    end
  end

  def generate
    zone = @supplier_report.supplier.timezone
    @supplier_report.start!

    # getting delegate supplier ids too
    supplier_ids = @supplier_report.supplier.delegate_supplier_ids.unshift(@supplier_report.supplier.id)
    @report = @report_class.where("supplier_id in (#{supplier_ids.join(', ')})")
                           .between_dates(@supplier_report.start_date.in_time_zone(zone).beginning_of_day, @supplier_report.end_date.in_time_zone(zone).end_of_day)

    if @report_type == 'Orders'
      @report = @report.unconfirmed if @supplier_report.open_orders
      @report = @report.shipped if @supplier_report.shipping_only
      @report = @report.on_demand if @supplier_report.delivery_only
    end

    CSV.generate do |csv|
      csv << @report.column_names
      @report.each do |row|
        csv << row.attributes.map { |_k, v| format_value(v) }
      end

      file = StringIO.new(csv.string)
      @supplier_report.file = file
      @supplier_report.file.instance_write(:file_name, 'data.csv')
      @supplier_report.file.instance_write(:content_type, 'text/csv')
      @supplier_report.save!
    end

    @supplier_report.complete!
  rescue StandardError => e
    notify_sentry_and_log(e, e.message, { tags: { supplier_report_id: @supplier_report.id } })
    raise SupplierReportGenerationError
  end
end
