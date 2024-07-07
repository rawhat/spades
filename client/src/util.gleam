import gleam/http.{Http}
import gleam/http/request.{type Request}
import gleam/int
import gleam/result

pub fn when(check: Bool, then: return, otherwise: return) -> return {
  case check {
    True -> then
    False -> otherwise
  }
}

@external(javascript, "./spades_ui_ffi.mjs", "getHostnameAndPort")
fn get_hostname_and_port() -> #(String, String)

pub fn new_request() -> Request(String) {
  let #(hostname, port) = get_hostname_and_port()
  let port =
    port
    |> int.parse
    |> result.unwrap(80)

  let req =
    request.new()
    |> request.set_host(hostname)
    |> request.set_port(port)

  case port {
    80 -> req
    _n -> request.set_scheme(req, Http)
  }
}
