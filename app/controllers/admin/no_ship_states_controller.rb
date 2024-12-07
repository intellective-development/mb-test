class Admin::NoShipStatesController < Admin::BaseController
  before_action :load_no_ship_state_by_categories, only: [:index]

  def create
    flash[:error] = 'The No Ship States could not be updated' unless save_no_ship_states.success?

    load_no_ship_state_by_categories
    render action: :index
  end

  private

  def save_no_ship_states
    ::NoShipStates::Save.new(no_ship_state_params).call
  end

  def load_no_ship_state_by_categories
    @no_ship_state_by_categories = NoShipState.all.index_by(&:ship_category_id)
  end

  def no_ship_state_params
    params.fetch(:no_ship_state, {}).permit(states_by_category: {}).tap do |permitted|
      permitted[:states_by_category] =
        (params.dig(:no_ship_state, :states_by_category) || ActionController::Parameters.new).permit!
    end
  end
end
