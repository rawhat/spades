defmodule SpadesWeb.UserController do
  use SpadesWeb, :controller

  alias Spades.Accounts

  def show(conn, _params) do
    conn
    |> put_status(200)
  end

  def create(conn, %{"user" => user_params}) do
    {:ok, _user} = Accounts.create_user(user_params)

    conn
    |> put_status(203)
  end

  def update(conn, _params) do
    conn
    |> put_status(200)
  end
end
