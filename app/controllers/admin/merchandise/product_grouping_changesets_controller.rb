class Admin::Merchandise::ProductGroupingChangesetsController < Admin::BaseController
  load_and_authorize_resource
  def index; end

  def show; end

  def update
    psg = @product_grouping_changeset.product_grouping
    if @product_grouping_changeset.trigger(trigger_param.to_sym)
      if @product_grouping_changeset.new_metadata
        allowed_metadata = @product_grouping_changeset.new_metadata.slice(*WHITELIST)
        psg.update(allowed_metadata)
      end
      @product_grouping_changeset.new_properties&.each do |k, v|
        psg.set_property(k, v)
      end
      redirect_to admin_merchandise_product_updates_path, notice: "Changeset was #{@product_grouping_changeset.current_state}"
    else
      flash.now[:notice] = "Error triggering #{trigger_param}"
      render :show
    end
  end

  private

  WHITELIST = %w[name description product_type_id image_url].freeze

  def trigger_param
    params.require(:product_grouping_changeset).permit(:trigger).require(:trigger)
  end
end
