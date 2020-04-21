defmodule SpadesWeb.Controller.UserController do
  use SpadesWeb, :controller

  def create(conn, _params) do
    conn
    |> put_status(200)
  end
end
