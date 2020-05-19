defmodule SpadesWeb.SessionController do
  use SpadesWeb, :controller

  alias Spades.Accounts
  alias Spades.Accounts.User

  def show(conn, _params) do
    with id when not is_nil(id) <- get_session(conn, :user_id),
         %User{} = user <- Accounts.get_user_by(id: id),
         username <- user.username do
      conn
      |> put_status(200)
      |> json(%{session: %{username: username}})
    else
      _ ->
        conn
        |> put_status(401)
        |> json(%{error: "Invalid session"})
    end
  end

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

  def delete(conn, _params) do
    conn
    |> delete_session(:user_id)
    |> put_status(202)
    |> json(%{})
  end
end
