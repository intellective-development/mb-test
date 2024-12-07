class Admin::StorefrontLinksController < Admin::BaseController
  delegate      :sort_column, :sort_direction, to: :list_storefront_links
  helper_method :sort_column, :sort_direction
  before_action :load_storefront
  before_action :load_storefront_link, only: %i[show edit update destroy]

  def index
    @storefront_links = list_storefront_links.result
  end

  def new
    @storefront_link = StorefrontLink.new
  end

  def create
    @storefront_link = create_storefront_link.storefront_link

    redirect_to(action: :index) and return if create_storefront_link.success?

    flash[:error] = 'The storefront link could not be saved'
    render action: :new
  end

  def update
    redirect_to(action: :index) and return if update_storefront_link(storefront_link_params).success?

    flash[:error] = 'The storefront link could not be updated'
    render action: :edit
  end

  def destroy
    redirect_to(action: :index) and return if delete_storefront_link.success?

    flash[:error] = 'The storefront link could not be deleted'
    render action: :index
  end

  private

  def list_storefront_links
    @list_storefront_links ||= ::StorefrontLinks::List.new(params).call
  end

  def load_storefront
    @storefront = Storefront.find(params[:storefront_id])
  end

  def load_storefront_link
    @storefront_link = StorefrontLink.find(params[:id])
  end

  def create_storefront_link
    @create_storefront_link ||= ::StorefrontLinks::Create.new(storefront_link_params).call
  end

  def update_storefront_link(update_params)
    ::StorefrontLinks::Update.new(@storefront_link, update_params).call
  end

  def delete_storefront_link
    ::StorefrontLinks::Delete.new(@storefront_link).call
  end

  def storefront_link_params
    params.require(:storefront_link).permit(
      :name, :area, :url, :link_type, :storefront_id
    )
  end
end
