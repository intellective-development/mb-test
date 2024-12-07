class ResponseError < StandardError
  def initialize(message)
    super 'Error creating Asana Task:' << String(message || 'Unexpected response while creating Asana Task')
  end
end

class AsanaService
  require 'asana'

  WORKSPACE_ID = '23906504477708'.freeze
  PROJECT_ID = '1204101151336165'.freeze
  OVER_500_PID = '1164694678111009'.freeze
  ORIGINAL_NAME_CHANGE_PROJECT_ID = '522027671210037'.freeze
  # FAILED_DELIVERY_PID = '1170070363221233'.freeze
  # ORDER_ERRORS_PID = '1170070363221237'.freeze
  # DOORDASH_ERRORS_PID = '1171018405346561'.freeze
  SEVEN_ELEVEN_PROJECT_ID = '1199722054507725'.freeze

  UNCONFIRMED_TAG_ID = '67111864759617'.freeze
  UNCONFIRMED_SCHEDULED_TAG_ID = '1176879823299043'.freeze
  CUSTOM_GIFT_CARD_TAG_ID = '1200032095364226'.freeze
  COMMENT_TAG_ID = '66927704145508'.freeze
  FRAUD_TAG_ID = '66927704145511'.freeze
  PROMO_ABUSE_TAG_ID = '1147161696709496'.freeze
  OUT_OF_HOURS_TAG_ID = '67115971785162'.freeze
  BILLING_ISSUE_TAG_ID = '1203118649147423'.freeze
  SUBSCRIPTION_ERROR_TAG_ID = '1179894889051149'.freeze
  CORPORATE_ORDERS_PROJECT_ID = '1199636709549529'.freeze
  RECENT_GIFT_CARD_ISP = '1200292947365689'.freeze
  CANCELLATION_ISSUE_TAG_ID = '1206265936086844'.freeze
  SHIPPING_ISSUE_TAG_ID = '1200526765283369'.freeze

  SEVEN_ELEVEN_GENERAL_TAG = '1199407787379249'.freeze
  SEVEN_ELEVEN_LINE_ITEM_EDIT_TAG = '1199407787379250'.freeze
  SEVEN_ELEVEN_CANCELLATION_TAG = '1199407787379251'.freeze
  SEVEN_ELEVEN_FAILED_DELIVERY_TAG = '1199407787379252'.freeze

  def initialize; end

  def create_task(params)
    if ENV['ASANA_PERSONAL_ACCESS_TOKEN'].blank?
      Rails.logger.info("[Development] AsanaService: #{params}")
    else
      task_params = generic_params.merge(params).symbolize_keys
      task_params[:tags] = task_params[:tags].map(&:to_s) if task_params[:tags].present?
      result = client.tasks.create(task_params)

      raise ResponseError, task_params[:name] unless result&.gid
    end
  end

  private

  def generic_params
    {
      workspace: AsanaService::WORKSPACE_ID,
      projects: [AsanaService::PROJECT_ID],
      due_at: 30.minutes.since.iso8601
    }
  end

  def client
    @client ||= Asana::Client.new do |c|
      c.authentication :access_token, ENV['ASANA_PERSONAL_ACCESS_TOKEN']
      c.log_asana_change_warnings false
    end
  end
end
