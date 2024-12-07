# This service handles profile syncing to OneSignal and push notification sends
class OneSignalService
  require 'faraday'

  attr_accessor :user, :one_signal_id

  def initialize(user_id)
    @user = User.find(user_id)
    raise "User #{user_id} does not exist." if @user.nil?

    @one_signal_id = @user.one_signal_id
    raise "User #{user_id} does not have a One Signal ID" if @one_signal_id.blank?
  end

  def update_profile
    response = Faraday.put("https://onesignal.com/api/v1/players/#{one_signal_id}",
                           update_params.to_json,
                           'Content-Type' => 'application/json')

    case response.status
    when 200
      Rails.logger.info("User #{user.id} updated in OneSignal")
    else
      Rails.logger.error("Error updating OneSignal for user #{user.id}: #{response.body}")
    end
  end

  private

  def update_params
    {
      tags: user.profile.one_signal_tags.reduce({}, :merge),
      amount_spent: user.orders.finished.joins(:order_amount).sum(:taxed_total).to_f.round_at(2)
    }
  end
end
