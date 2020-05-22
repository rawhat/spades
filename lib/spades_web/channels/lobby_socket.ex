defmodule SpadesWeb.LobbySocket do
  use Phoenix.Socket

  channel "lobby:*", SpadesWeb.LobbyChannel

  def connect(_params, socket, _connect_info) do
    {:ok, socket}
  end

  def id(_socket), do: nil
end
