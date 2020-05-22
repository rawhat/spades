defmodule SpadesWeb.LobbyChannel do
  use Phoenix.Channel

  alias Spades.Game.GameManager

  def join("lobby:*", _params, socket) do
    games = GameManager.active_games()
    {:ok, %{games: games}, socket}
  end
end
