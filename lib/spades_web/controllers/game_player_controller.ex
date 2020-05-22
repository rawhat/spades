defmodule SpadesWeb.GamePlayerController do
  use SpadesWeb, :controller

  alias Spades.Game.GameManager

  def show(conn, %{"id" => id, "name" => name}) do
    state = GameManager.get_game_state_for_player(id, name)
    json(conn, %{game: state})
  end

  def create(conn, %{"id" => id, "name" => name, "team" => team}) do
    user_id = get_session(conn, :user_id)
    GameManager.add_player(id, id: user_id, name: name, team: team)
    state = GameManager.get_game_state_for_player(id, name)
    json(conn, %{game: state})
  end
end
