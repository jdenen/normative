defmodule Test do
  defmodule Struct do
    @type t :: %__MODULE__{a: String.t()}
    defstruct [:a]
  end

  defmodule A do
    use Normative, version: 1

    defdata do
      a(type: String.t(), spec: is_binary)
      b(type: float(), default: 42.0)
    end
  end

  defmodule B do
    use Normative, version: 0.1

    defdata do
      a(type: Struct.t(), schema: %Struct{a: spec(is_binary)})
    end
  end

  defmodule Migrate do
    use Normative, version: 2

    defdata do
      a(type: String.t(), spec: is_binary)
    end

    def migrate(1, %{a: value}) do
      struct(__MODULE__, a: to_string(value))
    end
  end

  defmodule Equation do
    use Normative, version: V1

    defdata do
      left(type: integer, spec: is_integer)
      right(type: integer, spec: is_integer)
      operator(type: atom, spec: one_of([:+, :-, :*, :/]))
      result(type: integer | float, spec: is_integer or is_float)
    end

    def on_new(%{left: a, right: b, operator: :*} = data) do
      %{data | result: a * b}
    end
  end

  defmodule Collection do
    use Normative, version: "99"

    defdata do
      a(type: keyword, spec: coll_of({spec(is_atom), spec(is_binary)}), default: [one: "1"])
      b(type: integer | float, spec: one_of([spec(is_integer), spec(is_float)]), default: 1.0)
      c(type: [integer], spec: coll_of(spec(is_integer), min_count: 2), default: [1, 2, 3])
    end
  end
end
