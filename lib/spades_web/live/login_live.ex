defmodule SpadesWeb.LoginLive do
  use Phoenix.LiveView

  def mount(_params, _map, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~L"""
    <div class="container mx-auto">
      <form phx-change="change" phx-submit="submit">
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

  def handle_event("change", %{"username" => username, "password" => password}, socket) do
    IO.puts("username: #{username}, password: #{password}")
    {:noreply, socket}
  end
end
