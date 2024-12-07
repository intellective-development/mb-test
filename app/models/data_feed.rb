# == Schema Information
#
# Table name: data_feeds
#
#  id                       :integer          not null, primary key
#  active                   :boolean          default(FALSE), not null
#  last_fetched             :datetime
#  url                      :string(255)
#  digest                   :string(255)
#  frequency                :integer          default(24)
#  supplier_id              :integer
#  created_at               :datetime
#  updated_at               :datetime
#  mode                     :string(255)
#  inventory_threshold      :integer          default(2)
#  remove_items_not_present :boolean          default(TRUE), not null
#  feed_type                :integer
#  update_products          :boolean          default(FALSE), not null
#  last_pull_count          :integer
#  deleted_at               :datetime
#  prices_url               :string
#  store_number             :string
#  active_only              :boolean          default(FALSE)
#
# Indexes
#
#  index_data_feeds_on_active       (active)
#  index_data_feeds_on_supplier_id  (supplier_id)
#

class DataFeedInactiveError < StandardError; end

class DataFeed < ActiveRecord::Base
  has_paper_trail ignore: %i[last_pull_count last_fetched updated_at created_at digest]

  validates :url, presence: true, uniqueness: false

  belongs_to :supplier
  has_many :inventory_imports

  scope :active,    -> { where(active: true) }
  scope :inactive,  -> { where(active: false) }
  scope :visible,   -> { where(deleted_at: nil) }

  # These are the basic types of feed which we support. The primary difference
  # between them is how we handle updates - generally for file based feeds we
  # will calculate the MD5 of the file and use this to determine if it has been
  # updaed. With others we will generally use a timestamp.
  enum feed_type: {
    json: 0,
    csv: 1,
    dbf: 2,
    xls: 3,
    api: 4,
    database: 5
  }

  #-----------------------------------
  # Class methods
  #-----------------------------------

  def self.admin_grid(params = {})
    # Default to showing active feeds.
    # params[:active] = true unless params[:active].present?
    # params[:inactive] = true unless params[:inactive].present?
    # # [params[:active], params[:inactive]].each{|p| p = true } unless params[:active].present? || params[:active].present?

    grid = if params[:name].present?
             DataFeed.joins(:supplier).where('lower(suppliers.name) LIKE ?', "%#{params[:name].downcase}%")
           else
             DataFeed.joins('LEFT OUTER JOIN suppliers ON suppliers.id = data_feeds.supplier_id').order('suppliers.name desc')
           end
    grid = grid.active if params[:active].present? && params[:inactive].blank?
    grid = grid.inactive if params[:inactive].present? && params[:active].blank?
    # grid = grid.none if !params[:inactive].present? && !params[:active].present?
    grid
  end

  #-----------------------------------
  # Instance methods
  #-----------------------------------

  def fetch
    raise DataFeedInactiveError unless active?

    # TODO: BC: combine fetch and process here, check that the etag on the service has changed otherwise don't process_feed

    # If the feed has not changed, then no need to process it again.
    importer = ProductImport.new(self, false)
    if feed_updated?(importer.etag)
      update!(digest: importer.etag)
      importer.import_record.finish_import(success: true, has_changed: true)
      importer.process_feed
    else
      importer.import_record.finish_import(importer.counts.merge(success: true, has_changed: false))
    end

    # TODO: Think about this - technically its last attempted fetch - do we
    # need a way to indicate last successful fetch?
    update_last_fetched
  end

  # this function is similar to fetch, but doesn't check the digest
  # and attempts to process the feed regardless (useful for manipulating feeds on the console)
  def process(force = false)
    raise DataFeedInactiveError unless active?

    ProductImport.new(self, force).process_feed
  end

  def stale?
    last_fetched ? (last_fetched + frequency.hours) < Time.zone.now : true
  end

  def activate
    update(active: true)
  end

  def deactivate
    update(active: false)
  end

  def feed_updated?(etag)
    etag != digest
  end

  def update_last_fetched
    update(last_fetched: Time.zone.now)
  end

  def clear_digest
    update(digest: nil) if digest.present?
  end
end
