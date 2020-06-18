defmodule SpadesWeb.Router do
  use SpadesWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {SpadesWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_session
    plug :put_secure_browser_headers
  end

  pipeline :game do
    plug :game_exists
    plug SpadesWeb.Auth
  end

  pipeline :auth do
    plug SpadesWeb.Auth
  end

  scope "/api", SpadesWeb do
    pipe_through :api

    resources "/user", UserController, only: [:show, :create, :update]
    resources "/session", SessionController, only: [:create]
    resources "/session", SessionController, only: [:show, :delete], singleton: true

    scope "/game" do
      get "/", GameController, :list
      post "/", GameController, :create

      pipe_through :game

      get "/:id", GameController, :show
      put "/:id", GameController, :update

      post "/:id/player", GamePlayerController, :create
      get "/:id/player/:name", GamePlayerController, :show
      put "/:id/player/:name/call", GamePlayerController, :call
      put "/:id/player/:name/play", GamePlayerController, :play
    end
  end

  scope "/", SpadesWeb do
    pipe_through :browser

    live "/", LoginLive
    live "/create_account", CreateAccountLive

    # pipe_through :auth

    live "/lobby", LobbyLive
  end

  defp game_exists(conn, _) do
    case Spades.Game.GameManager.exists?(conn.params["id"]) do
      true -> conn
      _ -> put_status(conn, 404) |> json(%{error: "Game not found"}) |> halt()
    end
  end
end
