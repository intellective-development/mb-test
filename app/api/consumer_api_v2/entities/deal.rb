class ConsumerAPIV2::Entities::Deal < Grape::Entity
  delegate :short_title, :long_title, to: :presenter

  expose :short_title
  expose :long_title

  def presenter
    @presenter = Deal::Presenter.new(object)
  end
end
