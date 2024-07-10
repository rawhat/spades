import gleam/option.{None}
import gleam/uri.{type Uri}
import lustre
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import modem
import spades_ui/create_user
import spades_ui/lobby
import spades_ui/login

pub type Msg {
  RouteChanged(Route)
  LoginMsg(login.Msg)
  CreateMsg(create_user.Msg)
  LobbyMsg(lobby.Msg)
}

pub type Route {
  Create
  Home
  Lobby
  Login
  Game(id: String)
  NotFound(path: String)
}

fn get_route(uri: Uri) -> Route {
  case uri.path_segments(uri.path) {
    [] -> Home
    ["login"] -> Login
    ["create"] -> Create
    ["lobby"] -> Lobby
    ["game", id] -> Game(id)
    _ -> NotFound(uri.path)
  }
}

pub fn on_url_change(uri: Uri) -> Msg {
  uri
  |> get_route
  |> RouteChanged
}

pub type Model {
  Model(
    route: Route,
    login: login.Model,
    create: create_user.Model,
    lobby: lobby.Model,
  )
}

fn init(initial_route: Uri) -> #(Model, Effect(Msg)) {
  #(
    Model(
      route: get_route(initial_route),
      login: login.init(),
      create: create_user.init(),
      lobby: lobby.init(),
    ),
    modem.init(on_url_change),
  )
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    RouteChanged(route) -> #(Model(..model, route: route), effect.none())
    CreateMsg(create_user.OnCreate) -> #(
      Model(..model, route: Lobby),
      effect.map(lobby.start_lobby_socket(), LobbyMsg),
    )
    LoginMsg(login.LoginSuccess) -> #(
      Model(..model, route: Lobby),
      effect.map(lobby.start_lobby_socket(), LobbyMsg),
    )
    LoginMsg(login_msg) -> {
      let update = login.update(model.login, login_msg)
      #(Model(..model, login: update.0), effect.map(update.1, LoginMsg))
    }
    CreateMsg(create_msg) -> {
      let update = create_user.update(model.create, create_msg)
      #(Model(..model, create: update.0), effect.map(update.1, CreateMsg))
    }
    LobbyMsg(lobby.CreateSuccess(game_id)) -> {
      #(model, modem.push("/game/" <> game_id, None, None))
      // #(Model(..model, route: Game(game_id)), effect.none())
    }
    LobbyMsg(lobby_msg) -> {
      let update = lobby.update(model.lobby, lobby_msg)
      #(Model(..model, lobby: update.0), effect.map(update.1, LobbyMsg))
    }
  }
}

fn view(model: Model) -> Element(Msg) {
  case model.route {
    Home -> {
      html.div([], [
        element.text("root page"),
        html.a([attribute.href("/login")], [element.text("login")]),
      ])
    }
    Login -> {
      element.map(login.view(model.login), LoginMsg)
    }
    Create -> {
      element.map(create_user.view(model.create), CreateMsg)
    }
    Lobby -> {
      element.map(lobby.view(model.lobby), LobbyMsg)
    }
    Game(id) -> {
      html.div([], [element.text("we in a game: " <> id)])
    }
    NotFound(path) -> html.div([], [element.text("Path not found: " <> path)])
  }
}

pub fn main() {
  let assert Ok(initial_route) = modem.initial_uri()
  let app = lustre.application(init, update, view)

  lustre.start(app, "#app", initial_route)
}
