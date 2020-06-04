defmodule Spades.Game.GameRecord do
  # defmacro __using__(erl_mod: erl_mod, module: module, record_name: record_name) do
  # erl_record = String.downcase(record_name) |> String.to_atom()

  # record =
  # Record.extract(
  # erl_record,
  # from: "gen/src/#{erl_mod}_#{record_name}.hrl"
  # )

  # keys = :lists.map(&elem(&1, 0), record)
  # vals = :lists.map(&{&1, [], nil}, keys)
  # pairs = :lists.zip(keys, vals)

  # quote do
  # defstruct unquote(keys)

  # def to_record(%unquote(module){unquote_splicing(pairs)}) do
  # {unquote(erl_record), unquote_splicing(vals)}
  # end

  # def from_record(s) do
  # %unquote(module){unquote_splicing(pairs)}
  # end

  ## def to_record(%unquote(module){}) do
  ## asdfasdfad
  ## {erl_mod, unquote_splicing(vals)}
  ## end

  ## def to_record(quote(unquote_splicing(unquote(pairs)))) do
  ## quote do
  ## {unquote(erl_mod), unquote_splicing(vals)}
  ## end
  ## end

  ## def from_record({unquote(erl_mod), unquote_splicing(unquote(vals))}) do
  ## %unquote(module){unquote_splicing(pairs)}
  ## end
  ## end
  # end
  # end
  defmacro __using__(erl_mod: erl_mod, module: module, record_name: record_name) do
    quote do
      require Record

      record = unquote(record_name |> String.downcase() |> String.to_atom())

      Record.defrecord(record,
        from: "gen/src/#{unquote(erl_mod)}_#{unquote(record_name)}.hrl"
      )
    end
  end
end
