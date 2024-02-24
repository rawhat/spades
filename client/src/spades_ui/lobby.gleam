import gleam/dict.{type Dict}
import gleam/dynamic.{type Decoder}
import gleam/function
import gleam/json
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/result
import gleam/string
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html.{div}
import lustre_websocket as ws
import lustre/ui/box
import lustre/ui/centre
import lustre/ui/sequence
import lustre/ui/stack
import lustre/ui

pub type Msg {
  Websocket(ws.WebSocketEvent)
}

pub type Model {
  Model(ws: Option(ws.WebSocket), games: Dict(Int, GameEntry))
}

pub fn init() -> Model {
  Model(ws: None, games: dict.new())
}

pub fn start_lobby_socket() -> Effect(Msg) {
  ws.init("/socket/lobby", Websocket)
}

// TODO:  share these with the back-end encoders?
pub type GameEntry {
  GameEntry(id: Int, name: String, players: Int)
}

fn game_entry_decoder() -> Decoder(GameEntry) {
  dynamic.decode3(
    GameEntry,
    dynamic.field("id", dynamic.int),
    dynamic.field("name", dynamic.string),
    dynamic.field("players", dynamic.int),
  )
}

fn message_decoder() -> Decoder(Dict(Int, GameEntry)) {
  dynamic.any([
    function.compose(dynamic.list(game_entry_decoder()), fn(res) {
      result.map(res, fn(games) {
        list.fold(games, dict.new(), fn(acc, game) {
          dict.insert(acc, game.id, game)
        })
      })
    }),
    function.compose(game_entry_decoder(), fn(res) {
      result.map(res, fn(game) { dict.from_list([#(game.id, game)]) })
    }),
  ])
}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    Websocket(ws.OnOpen(sock)) -> #(
      Model(..model, ws: Some(sock)),
      effect.none(),
    )
    Websocket(ws.OnMessage(msg)) -> {
      json.decode(msg, message_decoder())
      |> result.map(fn(games) {
        #(Model(..model, games: dict.merge(model.games, games)), effect.none())
      })
      |> result.lazy_unwrap(fn() { #(model, effect.none()) })
    }
    Websocket(ws.OnClose(_reason)) -> #(Model(..model, ws: None), effect.none())
  }
}

pub fn view(model: Model) -> Element(Msg) {
  div([], [element.text(string.inspect(model.games))])
}
