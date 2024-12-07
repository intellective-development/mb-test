class Admin::UserDatas::ReferralsController < Admin::BaseController
  helper_method :sort_column, :sort_direction

  def index
    @referrals = Referral.order("#{sort_column} #{sort_direction}")
                         .page(pagination_page)
                         .per(pagination_rows)
  end

  def show
    @referral = Referral.find(params[:id])
  end

  private

  def sort_column
    Referral.column_names.include?(params[:sort]) ? params[:sort] : 'created_at'
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : 'asc'
  end
end
