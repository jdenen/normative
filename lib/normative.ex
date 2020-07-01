defmodule Normative do
  @callback s() :: %Norm.Core.Schema{}
  @callback new(map | keyword) :: {:ok, struct} | {:error, term}

  defmacro defdata(do: {:__block__, _, lines}) do
    write_ast(lines, __CALLER__.module)
  end

  defmacro defdata(do: line) do
    List.wrap(line)
    |> write_ast(__CALLER__.module)
  end

  defmacro __using__(_) do
    quote do
      import Normative
      import Norm

      @behaviour Normative

      @impl true
      def new(fields) do
        struct(__MODULE__, fields)
        |> Norm.conform(__MODULE__.s())
      end
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
