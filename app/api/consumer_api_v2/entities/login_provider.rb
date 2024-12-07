# frozen_string_literal: true

# ConsumerAPIV2::Entities::LoginProvider
#
# Entities for login provider
# rubocop:disable Style/ClassAndModuleChildren
class ConsumerAPIV2::Entities::LoginProvider < Grape::Entity
  DISPLAYED_CHARACTER_AMOUNT = 4

  expose :key
  expose :username

  private

  def username
    object.key.include?('sms') ? build_phone_number : build_email
  end

  def build_phone_number
    phone = object.registered_account.phone_number
    "*******#{phone.last(4)}"
  end

  def build_email
    splitted_email = object.registered_account.email.split(/@/)

    email_prefix = splitted_email.first
    email_domain = splitted_email.last

    prefix_size = email_prefix.size
    displayed_character_amount = prefix_size > 4 ? DISPLAYED_CHARACTER_AMOUNT : (prefix_size / 2).to_i

    "*******#{email_prefix.last(displayed_character_amount)}@#{email_domain}"
  end
end
# rubocop:enable Style/ClassAndModuleChildren
