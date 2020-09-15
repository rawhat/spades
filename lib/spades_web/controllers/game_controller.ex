defmodule SpadesWeb.GameController do
  use SpadesWeb, :controller

  alias Spades.Accounts
  alias Spades.Game.GameManager
  alias Spades.Game

  def list(conn, _params) do
    games = GameManager.active_games()
    json(conn, %{games: games})
  end

  def create(conn, %{"name" => name}) do
    user_id = get_session(conn, :user_id)
    id = GameManager.next_id()
    GameManager.start_link(id: id, name: name, game: Game.new(id, name, user_id))

    creator = Accounts.get_user_by(id: user_id)

    GameManager.add_player(id, id: user_id, name: creator.username, position: :north)

    game_state = %{id: id, name: name, players: 1}
    SpadesWeb.Endpoint.broadcast!("lobby:*", "update_game", game_state)

    json(conn, game_state)
  end

  def show(conn, %{"id" => id}) do
    game = GameManager.get_game_state(id)
    json(conn, %{game: game})
  end

  def update(conn, %{"id" => _id}) do
    json(conn, %{status: "ok"})
  end
end
