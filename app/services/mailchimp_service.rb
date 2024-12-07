class MailchimpService
  require 'gibbon'

  BATCH_SIZE = 250

  def initialize(test_mode = false)
    @test_mode = test_mode
  end

  # Since we are using upsert, this method is used to both create
  # and update subscribers.
  def subscribe_user_to_list(user_id, list_id)
    return true if disabled?

    return true if Rails.env.test? && !@test_mode

    user = User.includes(:profile).find_by(id: user_id)
    return false unless list_id && user

    perform_upsert(list_id, user.email, user.mailchimp_sync_data)
  rescue Gibbon::MailChimpError => e
    # Member Exists is returned if a user has unsubscribed or otherwise been permanetly
    # removed from the list, generally in these cases we don't care about the error so
    # suppress it. In future it may be useful to maintain a flag on the user and set
    # it based on the MC status.
    raise e unless ['Member Exists', 'Member In Compliance State'].include?(e.title)
  end

  def subscribe_non_user_to_list(data, list_id)
    return true if disabled?

    return true if Rails.env.test? && !@test_mode
    return false unless data && list_id

    perform_upsert(list_id, data[:email_address], data)
  end

  def unsubscribe_user_from_list(user_id, list_id)
    return true if disabled?

    return true if Rails.env.test? && !@test_mode

    user = User.find_by(id: user_id)
    return false unless list_id && user

    perform_upsert(list_id, user.email, status: 'unsubscribed')
  rescue Gibbon::MailChimpError => e
    nil
  end

  def batch_update_user_list
    return true if disabled?

    User.includes(:profile).find_in_batches(batch_size: BATCH_SIZE) do |batch|
      operations = []
      batch.each do |user|
        operations << {
          method: 'POST',
          path: "lists/#{ENV['MAILCHIMP_USER_LIST_ID']}/members/#{hash_string(user.email)}",
          body: user.mailchimp_sync_data.to_json
        }
      end
      gibbon.batches.create(body: {
                              operations: operations
                            })

      Rails.logger.info('Processed Batch')
    end
  end

  def update_prospecting_list
    return true if disabled?

    temp_list_id = ENV['MAILCHIMP_TEMP_LIST_ID']
    users_list_id = ENV['MAILCHIMP_USER_LIST_ID']
    prospect_list_id = ENV['MAILCHIMP_PROSPECT_LIST_ID']

    temp_list_members = gibbon.lists(temp_list_id).members.retrieve['members']
    return if temp_list_members.empty?

    temp_list_members.each do |member|
      member_email = member['email_address']
      unless check_if_member_exists(member_email, users_list_id) || check_if_member_exists(member_email, prospect_list_id)
        # Member is not in 'Registered users' and 'Prospect' lists, add it to 'Prospect' list
        data = {
          email_address: member_email,
          status: 'subscribed',
          merge_fields: {
            SOURCE: 'Paid-LP'
          }
        }
        perform_upsert(prospect_list_id, member_email, data)
      end
      # remove member from temp list
      gibbon.lists(temp_list_id).members(hash_string(member_email)).delete
    end
  end

  private

  def disabled?
    ENV['MAILCHIMP_STATUS'] == 'DISABLED'
  end

  def check_if_member_exists(email, list_id)
    gibbon.lists(list_id).members(hash_string(email)).retrieve
    true
  rescue StandardError
    false
  end

  def perform_upsert(list_id, email, data)
    gibbon.lists(list_id).members(hash_string(email)).upsert(body: data)
  end

  def hash_string(hashable)
    Digest::MD5.hexdigest(String(hashable).downcase)
  end

  def gibbon
    @client ||= Gibbon::Request.new(api_key: ENV['MAILCHIMP_KEY'], debug: Settings.debug_emails)
  end
end
