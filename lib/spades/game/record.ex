defmodule Spades.Game.Record do
  require Record

  defmacro __using__(opts) do
    name = Keyword.fetch!(opts, :name)
    from = Keyword.fetch!(opts, :from)

    fields = Record.extract(name, from: from)
    struct_fields = Keyword.keys(fields)
    vars = Macro.generate_arguments(length(struct_fields), __MODULE__)
    kvs = Enum.zip(struct_fields, vars)

    quote do
      @derive Jason.Encoder
      defstruct unquote(struct_fields)

      def from_record({unquote(name), unquote_splicing(vars)}) do
        %__MODULE__{unquote_splicing(kvs)}
      end

      def to_record(%__MODULE__{unquote_splicing(kvs)}) do
        {unquote(name), unquote_splicing(vars)}
      end

      def from_result({:ok, {unquote(name), unquote_splicing(vars)} = record}) do
        {:ok, from_record(record)}
      end

      def from_result({unquote(name), unquote_splicing(vars)} = record) do
        from_record(record)
      end

      def from_option({:some, {unquote(name), unquote_splicing(vars)} = record}) do
        {:ok, from_record(Tuple.delete_at(0, 1))}
      end

      def from_option({unquote(name), unquote_splicing(vars)} = record) do
        from_record(record)
      end

      def from_option(:none), do: nil

      def to_option(nil), do: :none
      def to_option(value), do: {:some, value}

      def parse(record), do: from_record(record)

      def unparse(%__MODULE__{} = struct), do: to_record(struct)

      defoverridable parse: 1, unparse: 1
    end
  end

  def option_as_nil(:none), do: nil
  def option_as_nil({:some, opt}), do: opt

  def nil_as_option(nil), do: :none
  def nil_as_option(value), do: {:some, value}
end
