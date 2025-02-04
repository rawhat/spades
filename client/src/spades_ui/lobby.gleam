import game/game.{type GameEntry}
import gleam/dict.{type Dict}
import gleam/dynamic/decode
import gleam/http.{Post}
import gleam/http/request
import gleam/int
import gleam/json
import gleam/option.{type Option, None, Some}
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html.{div, h1, h2}
import lustre/event
import lustre/server_component
import lustre/ui
import lustre/ui/button
import lustre/ui/sequence
import rsvp
import util

pub type Msg {
  NewGame(String)
  GamesAdded(Dict(Int, GameEntry))
  CreateGame
  CreateSuccess(game_id: String)
  CreateError(String)
}

pub type Model {
  Model(games: Dict(Int, GameEntry), new_game: Option(String), error: String)
}

pub fn init() -> Model {
  Model(games: dict.new(), new_game: None, error: "")
}

fn create_game(name: String) -> Effect(Msg) {
  util.new_request()
  |> request.set_path("/api/game")
  |> request.set_method(Post)
  |> request.set_body(
    json.object([#("name", json.string(name))])
    |> json.to_string,
  )
  |> rsvp.send(
    rsvp.expect_json(decode.at(["id"], decode.int), fn(res) {
      case res {
        Ok(game_id) -> CreateSuccess(int.to_string(game_id))
        Error(_reason) -> CreateError("Failed to create game")
      }
    }),
  )
}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    GamesAdded(games) -> #(
      Model(..model, games: dict.merge(model.games, games)),
      effect.none(),
    )
    NewGame(name) -> #(Model(..model, new_game: Some(name)), effect.none())
    CreateGame -> {
      case model.new_game {
        Some(new_game) -> #(model, create_game(new_game))
        None -> #(model, effect.none())
      }
    }
    CreateSuccess(_) -> #(model, effect.none())
    CreateError(error) -> #(Model(..model, error: error), effect.none())
  }
}

fn header(username: String) -> Element(Msg) {
  div(
    [
      attribute.style([
        #("width", "100%"),
        #("display", "flex"),
        #("justify-content", "space-between"),
        #("align-items", "center"),
        #("padding", "5px 10px"),
      ]),
    ],
    [
      h1([attribute.style([#("color", "#faf")])], [element.text("Spades")]),
      ui.sequence(
        [
          sequence.breakpoint("100%"),
          attribute.style([#("align-items", "center")]),
        ],
        [
          div([attribute.style([#("flex-basis", "auto")])], [
            element.text("Welcome, " <> username),
          ]),
          ui.button([attribute.style([#("flex-basis", "auto")])], [
            element.text("Logout"),
          ]),
        ],
      ),
    ],
  )
}

fn divider() -> Element(Msg) {
  html.hr([
    attribute.style([#("color", "lightgrey"), #("margin-inline", ".5rem")]),
  ])
}

fn new_game(game_name: Option(String)) -> Element(Msg) {
  case game_name {
    Some(name) -> {
      ui.sequence([], [
        ui.input([
          attribute.placeholder("Name"),
          attribute.value(name),
          event.on_input(NewGame),
        ]),
        ui.button([event.on_click(CreateGame)], [element.text("Create")]),
      ])
    }
    None -> {
      ui.button([button.success(), event.on_click(NewGame(""))], [
        element.text("New Game"),
      ])
    }
  }
}

pub fn view(model: Model) -> Element(Msg) {
  ui.stack([], [
    header("alex"),
    divider(),
    ui.centre([], h2([], [element.text("Lobby")])),
    divider(),
    ui.centre([], new_game(model.new_game)),
    server_component.component([server_component.route("/api/lobby")]),
  ])
}
