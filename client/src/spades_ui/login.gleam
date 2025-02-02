import gleam/http.{Post}
import gleam/http/request
import gleam/http/response.{Response}
import gleam/json
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html.{a}
import lustre/event
import lustre/ui
import lustre/ui/alert
import lustre/ui/stack
import rsvp
import util.{when}

pub type Model {
  Model(username: String, password: String, error: String)
}

pub type Msg {
  Username(value: String)
  Password(value: String)
  Login
  LoginSuccess
  LoginError(data: String)
}

pub fn init() -> Model {
  Model("", "", "")
}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    Username(value) -> #(Model(..model, username: value), effect.none())
    Password(value) -> #(Model(..model, password: value), effect.none())
    Login -> #(model, login(model.username, model.password))
    LoginSuccess -> #(model, effect.none())
    LoginError(err) -> #(Model(..model, error: err), effect.none())
  }
}

fn login(username: String, password: String) -> Effect(Msg) {
  let body =
    json.object([
      #(
        "session",
        json.object([
          #("username", json.string(username)),
          #("password", json.string(password)),
        ]),
      ),
    ])
    |> json.to_string

  let req =
    util.new_request()
    |> request.set_path("/api/session")
    |> request.set_method(Post)
    |> request.set_body(body)

  rsvp.send(
    req,
    rsvp.expect_ok_response(fn(resp) {
      case resp {
        Ok(_) -> LoginSuccess
        Error(rsvp.HttpError(Response(status: 403, ..))) ->
          LoginError("Invalid username or password")
        Error(_) -> LoginError("Failed to login")
      }
    }),
  )
}

pub fn view(model: Model) -> Element(Msg) {
  ui.centre(
    [],
    ui.box([], [
      stack.stack([stack.relaxed()], [
        ui.field(
          [],
          [element.text("Username")],
          ui.input([event.on_input(Username), attribute.value(model.username)]),
          [],
        ),
        ui.field(
          [],
          [element.text("Password")],
          ui.input([
            event.on_input(Password),
            attribute.value(model.password),
            attribute.type_("password"),
          ]),
          [],
        ),
        ui.button([event.on_click(Login)], [element.text("Login")]),
        when(
          model.error == "",
          element.none(),
          ui.alert([alert.error()], [element.text(model.error)]),
        ),
        a([attribute.href("/create"), attribute.type_("button")], [
          element.text("Create User"),
        ]),
      ]),
    ]),
  )
}
