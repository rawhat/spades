import gleam/map.{Map}
import gleam/otp/actor
import gleam/otp/process.{Sender}
import gleam/result

pub type SessionAction {
  Add(id: Int, pass: String)
  Remove(id: Int)
  Validate(caller: Sender(Result(Nil, Nil)), id: Int, pass: String)
}

pub type SessionState {
  SessionState(users: Map(Int, String))
}

pub fn start() -> Result(Sender(SessionAction), actor.StartError) {
  actor.start(
    SessionState(map.new()),
    fn(message, state) {
      case message {
        Add(id, pass) -> SessionState(users: map.insert(state.users, id, pass))
        Remove(id) -> SessionState(users: map.delete(state.users, id))
        Validate(caller, id, pass) -> {
          let resp =
            state.users
            |> map.get(id)
            |> result.then(fn(hashed) {
              case hashed == pass {
                True -> Ok(Nil)
                False -> Error(Nil)
              }
            })
          process.send(caller, resp)
          state
        }
      }
      |> actor.Continue
    },
  )
}
