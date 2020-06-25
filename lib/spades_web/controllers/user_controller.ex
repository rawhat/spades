defmodule SpadesWeb.UserController do
  use SpadesWeb, :controller

  alias Spades.Accounts
  alias Spades.Accounts.User

  def show(conn, _params) do
    conn
    |> put_status(200)
  end

  def create(conn, %{"user" => user_params}) do
    IO.inspect(user_params)

    case Accounts.register_user(user_params) do
      {:ok, user} ->
        conn
        |> put_status(203)
        |> SpadesWeb.Auth.login(user)
        |> json(%{username: user.username})

      {:error, %Ecto.Changeset{} = changeset} ->
        conn
        |> put_status(400)
        |> json(%{error: User.traverse_errors(changeset)})
    end
  end

  def update(conn, _params) do
    conn
    |> put_status(200)
  end
end
