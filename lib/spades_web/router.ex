defmodule SpadesWeb.Router do
  use SpadesWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :game do
    plug :game_exists
  end

  scope "/api", SpadesWeb do
    pipe_through :api

    scope "/user" do
      get "/:id", UserController, :show
      post "/", UserController, :create
      put "/", UserController, :update
    end

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

    get "/*path", PageController, :index
  end

  defp game_exists(conn, _) do
    case Spades.Game.GameManager.exists?(conn.params["id"]) do
      true -> conn
      _ -> put_status(conn, 404) |> json(%{error: "Game not found"}) |> halt()
    end
  end
end
