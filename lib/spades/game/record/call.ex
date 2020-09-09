defmodule Spades.Game.Record.Call do
  def parse(:none), do: nil
  def parse({:some, value}), do: from_record(value)

  def unparse(nil), do: :none
  def unparse(call), do: {:some, to_record(call)}

  def to_record(0), do: nil
  def to_record(-1), do: :blind_nil
  def to_record(value), do: {:value, value}

  def from_record(nil), do: 0
  def from_record(:blind_nil), do: -1
  def from_record({:value, value}), do: value
end
