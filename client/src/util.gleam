pub fn when(check: Bool, then: return, otherwise: return) -> return {
  case check {
    True -> then
    False -> otherwise
  }
}
