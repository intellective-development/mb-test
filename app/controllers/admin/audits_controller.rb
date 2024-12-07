class Admin::AuditsController < Admin::BaseController
  def index
    @versions = PaperTrail::Version.order(created_at: :desc)
                                   .page(params[:page])
                                   .per(25)
  end
end
