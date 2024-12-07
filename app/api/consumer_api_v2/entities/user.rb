class ConsumerAPIV2::Entities::User < Grape::Entity
  format_with(:uppercase) { |s| String(s).upcase }

  expose :id
  expose :email
  expose :hashed_email
  expose :first_name
  expose :last_name
  expose :birth_date
  expose :referral_code, format_with: :uppercase
  expose :payment_profiles, with: ConsumerAPIV2::Entities::PaymentProfile
  expose :shipping_addresses, with: ConsumerAPIV2::Entities::Address
  expose :default_shipping_address, with: ConsumerAPIV2::Entities::Address
  expose :order_count
  expose :referral_count
  expose :test_group

  # DEPRICATED: `access_token` has been depricated as a means of user authentication.
  # All clients should migrate to an OAuth based flow.
  expose :access_token, as: :user_token

  private

  # To protect a users privacy, we use a SHA256 hash of the users' email address when
  # sharing with 3rd parties (e.g. ad-networks)
  def hashed_email
    Digest::SHA256.hexdigest(String(object.email).downcase)
  end

  def payment_profiles
    Rails.cache.fetch("user:#{object.id}:payment_profiles:#{object.payment_profiles.credit_card.count}:#{object.payment_profiles.maximum(:updated_at)}", expires_in: 24.hours) do
      collection = object.payment_profiles.credit_card.order_by_default.order_by_recently_used + object.payment_profiles.apple_pay.order_by_default.order_by_recently_used.limit(1)
      collection.to_a.uniq
    end
  end

  def shipping_addresses
    Rails.cache.fetch("user:#{object.id}:shipping_addresses:#{object.shipping_addresses.count}:#{object.shipping_addresses.maximum(:updated_at)}:#{options[:doorkeeper_application_id]}", expires_in: 24.hours) do
      collection = options[:doorkeeper_application_id] ? object.shipping_addresses.order_by_client_recency(options[:doorkeeper_application_id]) : object.shipping_addresses.order_by_recently_used
      collection.to_a.uniq
    end
  end

  def order_count
    object.orders.finished.count
  end

  def referral_count
    object.referrals.count
  end
end
