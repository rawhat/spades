import decode.{type Decoder}
import gleam/dict.{type Dict}
import gleam/http.{Post}
import gleam/http/request
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html.{div, h1, h2}
import lustre/event
import lustre/ui
import lustre/ui/button
import lustre/ui/layout/sequence
import lustre_http
import lustre_websocket as ws
import util

pub type Msg {
  NewGame(String)
  Websocket(ws.WebSocketEvent)
  CreateGame
  CreateSuccess(game_id: String)
  CreateError(String)
}

pub type Model {
  Model(
    ws: Option(ws.WebSocket),
    games: Dict(Int, GameEntry),
    new_game: Option(String),
    error: String,
  )
}

pub fn init() -> Model {
  Model(ws: None, games: dict.new(), new_game: None, error: "")
}

pub fn start_lobby_socket() -> Effect(Msg) {
  ws.init("/socket/lobby", Websocket)
}

// TODO:  share these with the back-end encoders?
pub type GameEntry {
  GameEntry(id: Int, name: String, players: Int)
}

fn game_entry_decoder() -> Decoder(GameEntry) {
  decode.into({
    use id <- decode.parameter
    use name <- decode.parameter
    use players <- decode.parameter
    GameEntry(id, name, players)
  })
  |> decode.field("id", decode.int)
  |> decode.field("name", decode.string)
  |> decode.field("players", decode.int)
}

fn message_decoder() -> Decoder(Dict(Int, GameEntry)) {
  decode.one_of([
    decode.list(game_entry_decoder())
      |> decode.then(fn(games) {
        list.fold(games, dict.new(), fn(acc, game) {
          dict.insert(acc, game.id, game)
        })
        |> decode.into
      }),
    game_entry_decoder()
      |> decode.then(fn(game) {
        decode.into(dict.from_list([#(game.id, game)]))
      }),
  ])
}

fn create_game(name: String) -> Effect(Msg) {
  util.new_request()
  |> request.set_path("/api/game")
  |> request.set_method(Post)
  |> request.set_body(
    json.object([#("name", json.string(name))])
    |> json.to_string,
  )
  |> lustre_http.send(
    lustre_http.expect_json(
      decode.from(decode.at(["id"], decode.int), _),
      fn(res) {
        case res {
          Ok(game_id) -> CreateSuccess(int.to_string(game_id))
          Error(_reason) -> CreateError("Failed to create game")
        }
      },
    ),
  )
}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    Websocket(ws.OnOpen(sock)) -> #(
      Model(..model, ws: Some(sock)),
      effect.none(),
    )
    Websocket(ws.OnTextMessage(msg)) -> {
      json.decode(msg, decode.from(message_decoder(), _))
      |> result.map(fn(games) {
        #(Model(..model, games: dict.merge(model.games, games)), effect.none())
      })
      |> result.lazy_unwrap(fn() { #(model, effect.none()) })
    }
    Websocket(ws.OnClose(_reason)) -> #(Model(..model, ws: None), effect.none())
    NewGame(name) -> #(Model(..model, new_game: Some(name)), effect.none())
    CreateGame -> {
      case model.new_game {
        Some(new_game) -> #(model, create_game(new_game))
        None -> #(model, effect.none())
      }
    }
    CreateSuccess(_) -> #(model, effect.none())
    CreateError(error) -> #(Model(..model, error: error), effect.none())
    Websocket(ws.OnBinaryMessage(_msg)) | Websocket(ws.InvalidUrl) -> #(
      model,
      effect.none(),
    )
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

fn game_list(_games: Dict(Int, GameEntry)) -> Element(Msg) {
  div([], [])
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
    game_list(model.games),
  ])
}
