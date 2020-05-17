defmodule SpadesWeb.SessionController do
  use SpadesWeb, :controller

  def create(
        conn,
        %{"session" => %{"username" => username, "password" => password}}
      ) do
    case Spades.Accounts.authenticate_by_username_and_pass(username, password) do
      {:ok, user} ->
        conn
        |> SpadesWeb.Auth.login(user)
        |> json(%{username: username})

      {:error, _reason} ->
        conn
        |> put_status(403)
        |> json(%{error: "Invalid credentials"})
    end
  end
end
