class AdminAPIV1::Entities::User < Grape::Entity
  expose :id
  expose :email
  expose :first_name
  expose :last_name
  expose :access_token, as: :user_token
  expose :score_total_today do |_user|
    0 # Count.of("hunger_games##{user.id}").find_by(date: Time.zone.today) || 0
  end
end
