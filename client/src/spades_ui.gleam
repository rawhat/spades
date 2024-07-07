import lustre
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
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
  Route(path: String, hash: String)
}

pub type Model {
  Model(
    route: Route,
    login: login.Model,
    create: create_user.Model,
    lobby: lobby.Model,
  )
}

fn init(initial_route: Route) -> #(Model, Effect(Msg)) {
  #(
    Model(
      route: initial_route,
      login: login.init(),
      create: create_user.init(),
      lobby: lobby.init(),
    ),
    effect.none(),
  )
}

fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    RouteChanged(route) -> #(Model(..model, route: route), effect.none())
    CreateMsg(create_user.OnCreate) -> #(
      Model(..model, route: Route("/lobby", "")),
      effect.map(lobby.start_lobby_socket(), LobbyMsg),
    )
    LoginMsg(login.LoginSuccess) -> #(
      Model(..model, route: Route("/lobby", "")),
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
      #(Model(..model, route: Route("/game/" <> game_id, "")), effect.none())
    }
    LobbyMsg(lobby_msg) -> {
      let update = lobby.update(model.lobby, lobby_msg)
      #(Model(..model, lobby: update.0), effect.map(update.1, LobbyMsg))
    }
  }
}

fn view(model: Model) -> Element(Msg) {
  case model.route {
    Route("/", "") -> {
      html.div([], [
        element.text("root page"),
        html.a([attribute.href("/login")], [element.text("login")]),
      ])
    }
    Route("/login", "") -> {
      element.map(login.view(model.login), LoginMsg)
    }
    Route("/create", "") -> {
      element.map(create_user.view(model.create), CreateMsg)
    }
    Route("/lobby", "") -> {
      element.map(lobby.view(model.lobby), LobbyMsg)
    }
    _ -> {
      html.div([], [element.text("Not found")])
    }
  }
}

@external(javascript, "./spades_ui_ffi", "getInitialRoute")
fn get_initial_route() -> Route

@external(javascript, "./spades_ui_ffi", "setupRouter")
fn setup_router(dispatch: fn(Route) -> Nil) -> Nil

pub fn main() {
  let app = lustre.application(init, update, view)

  let initial_route = get_initial_route()

  let assert Ok(dispatch) = lustre.start(app, "#app", initial_route)

  setup_router(fn(route) { dispatch(RouteChanged(route)) })
}
