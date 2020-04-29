defmodule SpadesWeb.PageController do
  use SpadesWeb, :controller

  def index(conn, _params) do
    file = Path.join(:code.priv_dir(:spades), "index.html")
    |> File.read!()

    html(conn, file)
  end
end
