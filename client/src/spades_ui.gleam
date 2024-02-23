import lustre/element.{type Element}
import lustre/element/html
import lustre

pub type Model {
  Model(value: Int)
}

pub type Msg {
  Increment
  Decrement
}

fn init(_) -> Model {
  Model(0)
}

fn update(model: Model, msg: Msg) -> Model {
  case msg {
    Increment -> Model(value: model.value + 1)
    Decrement -> Model(value: model.value - 1)
  }
}

fn view(_model: Model) -> Element(Msg) {
  html.div([], [element.text("hello, world!")])
}

pub fn main() {
  let app = lustre.simple(init, update, view)

  lustre.start(app, "#root", 0)
}
