defmodule SpadesWeb.UserController do
  use SpadesWeb, :controller

  alias Spades.Accounts

  def show(conn, _params) do
    conn
    |> put_status(200)
  end

  def create(conn, %{"user" => user_params}) do
    case Accounts.register_user(user_params) do
      {:ok, user} ->
        IO.puts("hi")

        conn
        |> put_status(203)
        |> json(%{username: user.username})

      {:error, %Ecto.Changeset{} = changeset} ->
        IO.inspect(changeset.action)

        conn
        |> put_status(400)
        |> json(%{error: "Unable to create user"})
    end
  end

  def update(conn, _params) do
    conn
    |> put_status(200)
  end
end
