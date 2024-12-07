module AdminNotifierHelper
  def hunger_games_total_points
    @hunger_games.sum(:value)
  end

  def hunger_games_average
    Integer(hunger_games_total_points / @hunger_games.size)
  end
end
