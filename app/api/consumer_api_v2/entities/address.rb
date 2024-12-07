class ConsumerAPIV2::Entities::Address < Grape::Entity
  expose :id, unless: ->(_object, options) { options[:supplier] }
  expose :local_id
  expose :name,                   unless: ->(_object, options) { options[:supplier] }
  expose :company,                unless: ->(_object, options) { options[:supplier] }
  expose :address1
  expose :address2
  expose :city
  expose :state_name, as: :state
  expose :zip_code
  expose :phone, unless: ->(_object, options) { !options[:show_phone] && options[:supplier] }
  expose :latitude
  expose :longitude
  expose :default, unless: ->(_object, options) { options[:supplier] }

  private

  def local_id
    Digest::SHA256.hexdigest(String(object.id))
  end

  # We only want to indicate an item is default if it belongs to the current
  # doorkeeper application. If it belongs to another application, we will show it
  # but won't respect default.
  def default
    options[:doorkeeper_application_id] == object.doorkeeper_application_id ? object.default : false
  end
end
