defmodule SpadesWeb.GameSocket do
  use Phoenix.Socket

  channel "game:*", SpadesWeb.GameChannel

  def connect(_params, socket, _connect_info) do
    {:ok, socket}
  end

  # def id(socket), do: "user:#{socket.assigns.username}"
  def id(_socket), do: nil
end
