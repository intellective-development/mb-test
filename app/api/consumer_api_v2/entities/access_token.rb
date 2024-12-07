class ConsumerAPIV2::Entities::AccessToken < Grape::Entity
  format_with(:iso_timestamp) { |dt| dt&.iso8601 }

  expose :created_at, format_with: :iso_timestamp
  expose :expires_in
  expose :refresh_token
  expose :resource_owner
  expose :token_type
  expose :token, as: :access_token
  expose :jwt_token

  private

  def resource_owner
    object.resource_owner_id.present?
  end

  def jwt_token
    # when implemented, this is only used in kustomer on mobile for ios and is not used anywhere else
    # so, don't trust this as some sort of valid session
    options[:jwt_token] || ''
  end

  def token_type
    'bearer'
  end
end
