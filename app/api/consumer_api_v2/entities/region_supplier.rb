class ConsumerAPIV2::Entities::RegionSupplier < Grape::Entity
  expose :address, if: ->(object, _options) { object.address } do
    expose :address1 do |object, _options|
      object.address.address1
    end
    expose :address2 do |object, _options|
      object.address.address2
    end
    expose :city do |object, _options|
      object.address.city
    end
    expose :latitude do |object, _options|
      object.address.latitude
    end
    expose :longitude do |object, _options|
      object.address.longitude
    end
    expose :normalized_phone do |object, _options|
      object.address.normalized_phone
    end
    expose :phone do |object, _options|
      object.address.phone
    end
    expose :state_name do |object, _options|
      object.address.state_name
    end
    expose :zip_code do |object, _options|
      object.address.zip_code
    end
  end

  expose :delivery_hours, if: ->(object, _options) { object.delivery_hours } do |object, _options|
    object.delivery_hours.sort_by(&:wday).map do |hours|
      {
        ends_at: hours.ends_at,
        starts_at: hours.starts_at,
        wday: hours.wday
      }
    end
  end

  expose :display_name
  expose :id
  expose :permalink

  expose :profile do
    expose :categories do |object, _options|
      object.categories.transform_values(&:to_i)
    end
  end
end
