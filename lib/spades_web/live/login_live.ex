defmodule SpadesWeb.LoginLive do
  use SpadesWeb, :live_view

  alias Spades.Accounts

  def mount(_params, _map, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~L"""
    <div class="container mx-auto">
      <form phx-submit="submit">
        <div class="flex flex-col justify-end">
          <div class="flex py-5">
            <label class="px-5" for="username">Username</label>
            <input type="text" name="username">
          </div>
          <div class="flex py-5">
            <label class="px-5" for="password">Password</label>
            <input type="password" name="password">
          </div>
          <div class="flex justify-end">
            <button class="btn-primary">Login</button>
          </div>
        </div>
      </form>
    </div>
    """
  end

  def handle_event("submit", %{"username" => username, "password" => password}, socket) do
    case Accounts.authenticate_by_username_and_pass(username, password) do
      {:ok, user} ->
        IO.puts("woo! #{inspect(user)}")

        {:noreply,
         socket
         |> put_flash(:success, "Logged in!")
         |> push_redirect(to: Routes.live_path(socket, SpadesWeb.LobbyLive))}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Invalid username or password")}
    end
  end
end
