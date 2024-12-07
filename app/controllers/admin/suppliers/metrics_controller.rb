class Admin::Suppliers::MetricsController < Admin::BaseController
  def index
    @top_suppliers    = ::Supplier.active.order('score DESC NULLS LAST').limit(5)
    @bottom_suppliers = ::Supplier.active.order('score ASC NULLS LAST').limit(5)
    @order_surveys    = OrderSurvey.complete
                                   .includes(%i[user order])
                                   .order(updated_at: :desc)
                                   .page(params[:page])
                                   .per(25)
  end

  def survey_scores
    render json: OrderSurvey.complete.last_sixty_days.group(:score).count
  end
end
