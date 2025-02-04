import game/game.{type GameEntry}
import gleam/dict.{type Dict}
import gleam/erlang/process.{type Subject}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/json
import gleam/list
import gleam/option.{Some}
import gleam/otp/actor
import gleam/string
import lustre
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html.{div}
import lustre/server_component
import mist.{type Connection, type ResponseData}
import spades/game_manager.{type ManagerAction}
import spades/games
import spades/lobby_manager.{type LobbyAction, Join}
import spades/session.{type Session}

fn app() {
  lustre.application(init, update, view)
}

pub type ServerMessage {
  GameCreated(GameEntry)
  Patch(lustre.Patch(Msg))
}

pub type Msg {
  GameAdded(GameEntry)
}

pub type Model {
  Model(games: Dict(Int, GameEntry))
}

fn init(games: List(GameEntry)) -> #(Model, Effect(Msg)) {
  let games =
    list.fold(games, dict.new(), fn(acc, game) {
      dict.insert(acc, game.id, game)
    })
  #(Model(games:), effect.none())
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    GameAdded(game) -> {
      #(Model(games: dict.insert(model.games, game.id, game)), effect.none())
    }
  }
}

fn view(model: Model) -> Element(Msg) {
  div([], [element.text(string.inspect(model.games))])
}

pub fn start(
  req: Request(Connection),
  lobby_manager: Subject(LobbyAction),
  game_manager: Subject(ManagerAction),
  session: Session,
) -> Response(ResponseData) {
  mist.websocket(
    request: req,
    on_init: fn(_conn) {
      let lobby_subj = process.new_subject()
      process.send(lobby_manager, Join(session, lobby_subj))

      let assert Ok(games) = games.list(game_manager)

      let assert Ok(lobby) = lustre.start_actor(app(), games)

      let patch_subj = process.new_subject()

      process.send(
        lobby,
        server_component.subscribe(session.username, process.send(patch_subj, _)),
      )

      let patch_selector =
        process.new_selector()
        |> process.selecting(patch_subj, Patch)

      let lobby_selector =
        process.new_selector()
        |> process.selecting(lobby_subj, fn(send) {
          let lobby_manager.Send(entry) = send
          GameCreated(entry)
        })

      #(lobby, Some(process.merge_selector(patch_selector, lobby_selector)))
    },
    handler: fn(self, conn, msg) {
      case msg {
        mist.Text(json) -> {
          let action = json.decode(json, server_component.decode_action)
          case action {
            Ok(action) -> process.send(self, action)
            _ -> Nil
          }
          actor.continue(self)
        }
        mist.Custom(Patch(patch)) -> {
          let assert Ok(_) =
            patch
            |> server_component.encode_patch
            |> json.to_string
            |> mist.send_text_frame(conn, _)

          actor.continue(self)
        }
        mist.Custom(GameCreated(entry)) -> {
          process.send(self, lustre.dispatch(GameAdded(entry)))
          actor.continue(self)
        }
        mist.Binary(_) -> actor.continue(self)
        mist.Closed | mist.Shutdown -> actor.Stop(process.Normal)
      }
    },
    on_close: fn(self) { process.send(self, lustre.shutdown()) },
  )
}
