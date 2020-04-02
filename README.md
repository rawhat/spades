# Spades

To run the application using docker-compose, run:

  * `docker-compose build`
  * `docker-compose up`
  * Navigate to `localhost:3000` in your browser

Any file changes for the UI will recompile automatically and refresh the
application.  Currently the API does not support this.  It is usually useful
to get an interactive session with IEx.  To do so, instead run:

  `docker-compose run api iex -S mix phx.server`

The behavior should still be the same, but now you can interact with the
API modules directly, or type `recompile` to rebuild the application with
any changes.

## "To break you, of course."

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix
