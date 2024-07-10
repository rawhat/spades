import gleam/http.{Post}
import gleam/http/request
import gleam/json
import gleam/result
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html.{a}
import lustre/event
import lustre/ui
import lustre/ui/alert
import lustre/ui/field
import lustre/ui/layout/sequence
import lustre/ui/layout/stack
import lustre_http
import util.{when}

pub type Model {
  Model(
    username: String,
    password: String,
    password_repeat: String,
    error: String,
  )
}

pub type Msg {
  Username(value: String)
  Password(value: String)
  PasswordRepeat(value: String)
  Create
  OnCreate
  CreateError(err: String)
}

pub fn init() -> Model {
  Model("", "", "", "")
}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    Username(value) -> #(Model(..model, username: value), effect.none())
    Password(value) -> #(Model(..model, password: value), effect.none())
    PasswordRepeat(value) -> #(
      Model(..model, password_repeat: value),
      effect.none(),
    )
    Create -> #(model, create(model))
    OnCreate -> #(model, effect.none())
    CreateError(err) -> #(Model(..model, error: err), effect.none())
  }
}

fn create(model: Model) -> Effect(Msg) {
  let body =
    json.object([
      #(
        "user",
        json.object([
          #("username", json.string(model.username)),
          #("password", json.string(model.password)),
        ]),
      ),
    ])
    |> json.to_string

  let req =
    util.new_request()
    |> request.set_path("/api/user")
    |> request.set_method(Post)
    |> request.set_body(body)

  lustre_http.send(
    req,
    lustre_http.expect_anything(fn(res) {
      case result.is_ok(res) {
        True -> OnCreate
        False -> CreateError("Failed to create user")
      }
    }),
  )
}

pub fn view(model: Model) -> Element(Msg) {
  ui.centre(
    [],
    ui.box([], [
      ui.stack([stack.loose()], [
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
            attribute.type_("password"),
            event.on_input(Password),
            attribute.value(model.password),
          ]),
          [],
        ),
        ui.field(
          [
            when(
              model.password == model.password_repeat,
              attribute.none(),
              field.error(),
            ),
          ],
          [element.text("Password Repeat")],
          ui.input([
            attribute.type_("password"),
            event.on_input(PasswordRepeat),
            attribute.value(model.password_repeat),
          ]),
          when(model.password == model.password_repeat, [], [
            element.text("Passwords do not match"),
          ]),
        ),
        ui.sequence([sequence.relaxed()], [
          a([attribute.href("/login")], [element.text("Back to login")]),
          ui.button(
            [
              event.on_click(Create),
              when(
                model.username == ""
                  || model.password == ""
                  || model.password != model.password_repeat,
                attribute.disabled(True),
                attribute.none(),
              ),
            ],
            [element.text("Create")],
          ),
        ]),
        when(
          model.error == "",
          element.none(),
          ui.alert([alert.error()], [element.text(model.error)]),
        ),
      ]),
    ]),
  )
}
