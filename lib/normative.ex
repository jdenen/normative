defmodule Normative do
  @callback s() :: %Norm.Core.Schema{}
  @callback new(map | keyword) :: {:ok, struct} | {:error, term}
  @callback migrate(version :: term, struct) :: struct
  @callback on_new(struct) :: struct

  defmacro defdata(do: {:__block__, _, lines}) do
    write_ast(lines, __CALLER__.module)
  end

  defmacro defdata(do: line) do
    List.wrap(line)
    |> write_ast(__CALLER__.module)
  end

  defmacro __using__(opts) do
    version = Keyword.fetch!(opts, :version)

    quote do
      import Normative
      import Norm

      @behaviour Normative
      @before_compile Normative
      @version unquote(version)

      @impl true
      def new(fields) do
        data = struct(__MODULE__, fields) |> on_new()

        migrate(data.__vsn__, data)
        |> Norm.conform(__MODULE__.s())
      end

      @impl true
      def on_new(struct), do: struct

      defoverridable on_new: 1
    end
  end

  defmacro __before_compile__(_opts) do
    quote do
      @impl true
      def migrate(_version, x), do: x
    end
  end

  defp write_ast(ast, mod) do
    [
      required_fields(ast),
      struct_definition(ast),
      type_spec(ast, mod),
      define_schema(ast, mod)
    ]
  end

  defp define_schema(ast, mod) do
    specs = Enum.reduce(ast, [], &spec_or_schema(&1, :spec, &2))
    schemas = Enum.reduce(ast, [], &spec_or_schema(&1, :schema, &2))

    [
      {:@, [context: Elixir, import: Kernel], [{:impl, [], [true]}]},
      {:def, [],
       [
         {:s, [], Elixir},
         [
           do:
             {:schema, [context: Elixir, import: Norm],
              [{:%, [], [{:__aliases__, [alias: false], [mod]}, {:%{}, [], specs ++ schemas}]}]}
         ]
       ]}
    ]
  end

  defp spec_or_schema({name, _, [kwargs]}, key, acc) do
    case Keyword.get(kwargs, key) do
      nil -> acc
      val -> [{name, {key, [context: Elixir, import: Norm], [val]}} | acc]
    end
  end

  defp required_fields(ast) do
    required =
      Enum.filter(ast, fn {_, _, [kwargs]} -> Keyword.get(kwargs, :required) end)
      |> Enum.map(&elem(&1, 0))

    {:@, [], [{:enforce_keys, [], [required]}]}
  end

  defp struct_definition(ast) do
    fields =
      Enum.reduce(ast, [], fn {name, _, [kwargs]}, acc ->
        default = Keyword.get(kwargs, :default)
        [{name, default} | acc]
      end)
      |> Keyword.put_new(:__vsn__, {:@, [import: Kernel], [{:version, [], Elixir}]})

    {:defstruct, [context: Elixir, import: Kernel], [fields]}
  end

  defp type_spec(ast, mod) do
    fields =
      Enum.reduce(ast, [], fn {name, _, [kwargs]}, acc ->
        type = Keyword.fetch!(kwargs, :type)
        [{name, type} | acc]
      end)

    return_type = {:%, [], [{:__aliases__, [alias: false], [mod]}, {:%{}, [], fields}]}

    {:@, [context: Elixir, import: Kernel],
     [{:type, [], [{:"::", [], [{:t, [], Elixir}, return_type]}]}]}
  end
end
