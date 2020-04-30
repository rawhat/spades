defmodule SpadesWeb.PageController do
  use SpadesWeb, :controller

  def index(conn, _params) do
    file =
      Path.join(:code.priv_dir(:spades), "index.html")
      |> File.read()

    case file do
      {:ok, f} -> html(conn, f)
      _ -> render(conn, "index.html")
    end
  end
end
