module GuestAuthenticable
  def create_guest_user!(storefront_id)
    User.create!(user_attributes(storefront_id: storefront_id))
  end

  def create_user_with_params!(storefront_id, params)
    merged_params = params.merge(storefront_id: storefront_id)
    User.create! user_attributes(merged_params)
  end

  def create_guest_user
    User.create(user_attributes)
  end

  def user_attributes(acct_attributes = {})
    {
      account_attributes: account_attributes.merge(acct_attributes),
      utm_source: 'admin',
      utm_medium: 'admin',
      anonymous: true
    }
  end

  def account_attributes
    temp_password = SecureRandom.uuid
    {
      password: temp_password,
      password_confirmation: temp_password,
      email: "#{SecureRandom.uuid}@anonymo.us",
      contact_email: 'guest@account.com',
      first_name: 'Guest',
      last_name: 'Account'
    }
  end
end
