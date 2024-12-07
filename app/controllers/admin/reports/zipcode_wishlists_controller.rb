require 'csv'

class Admin::Reports::ZipcodeWishlistsController < Admin::Reports::BaseController
  def index
    respond_to do |want|
      want.html { @zipcode_wishlists = ::ZipcodeWaitlist.page(params[:page]).per(20) }
      want.csv { send_data waitlist_csv }
    end
  end

  private

  def waitlist_csv
    CSV.generate(col_sep: "\t") do |csv|
      csv << %w[zipcode email platform source added]
      ::ZipcodeWaitlist.find_each do |entry|
        csv << [entry.zipcode, entry.email, entry.platform, entry.source, entry.created_at]
      end
    end
  end
end
