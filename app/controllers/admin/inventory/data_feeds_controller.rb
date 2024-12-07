class Admin::Inventory::DataFeedsController < Admin::BaseController
  load_and_authorize_resource except: [:create]

  def index
    @feeds = DataFeed.includes(:supplier)
                     .visible
                     .admin_grid(params)
                     .order('data_feeds.active desc', 'suppliers.name asc')
                     .page(pagination_page)
                     .per(pagination_rows)
  end

  def new
    @feed = DataFeed.new
    @suppliers = Supplier.all.order(name: :desc)
    @parsers   = list_parsers
  end

  def create
    @feed = DataFeed.new(allowed_params)

    if @feed.save
      redirect_to action: :index
    else
      render action: :new, error: 'The datafeed could not be saved'
    end
  end

  def edit
    @feed       = DataFeed.visible.find(params[:id])
    @supplier   = @feed.supplier
    @suppliers  = Supplier.all.order(:name)
    @parsers    = list_parsers
  end

  def show
    @feed = DataFeed.visible.find(params[:id])
  end

  def update
    feed = DataFeed.visible.find(params[:id])
    feed.attributes = allowed_params

    if feed.save
      redirect_to action: :index
    else
      render action: :edit
    end
  end

  def activate
    feed = DataFeed.visible.find(params[:id])
    if feed.present?
      feed.active? ? feed.deactivate : feed.activate
      redirect_to action: :index
    end
  end

  private

  def allowed_params
    params.require(:data_feed).permit(:frequency, :url, :prices_url, :supplier_id, :mode, :inventory_threshold, :remove_items_not_present, :feed_type, :update_products, :store_number)
  end

  def list_parsers
    Dir['app/models/parsers/*.rb'].each { |file| load file }
    Parsers.constants.select { |c| Parsers.const_get(c).is_a? Class }.map { |c| c.to_s.underscore.upcase }.sort
  end
end
