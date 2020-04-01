defmodule SpadesWeb.GameController do
  use SpadesWeb, :controller

  alias Spades.Game.GameManager

  def list(conn, _params) do
    games = GameManager.active_games()
    json(conn, %{games: games})
  end

  def create(conn, _params) do
    id = GameManager.next_id()
    GameManager.start_link(id: id)
    json(conn, %{id: id})
  end

  def show(conn, %{"id" => id}) do
    game = GameManager.get_game_state(id)
    json(conn, %{game: game})
  end

  def update(conn, %{"id" => _id}) do
    json(conn, %{status: "ok"})
  end
end
