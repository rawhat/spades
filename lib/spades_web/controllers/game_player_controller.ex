defmodule SpadesWeb.GamePlayerController do
  use SpadesWeb, :controller

  alias Spades.Game.GameManager

  def show(conn, %{"id" => id, "name" => name}) do
    state = GameManager.get_game_state_for_player(id, name)
    json(conn, %{game: state})
  end

  def create(conn, %{"id" => id, "name" => name, "team" => team}) do
    GameManager.add_player(id, name: name, team: team)
    state = GameManager.get_game_state_for_player(id, name)
    json(conn, %{game: state})
  end
end
