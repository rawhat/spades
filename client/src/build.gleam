import esgleam

pub fn main() {
  esgleam.new(outdir: "./dist")
  |> esgleam.entry("spades_ui.gleam")
  |> esgleam.serve(dir: "./dist")
  |> esgleam.bundle
}
