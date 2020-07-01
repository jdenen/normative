defmodule Test do
  defmodule Struct do
    @type t :: %__MODULE__{a: String.t()}
    defstruct [:a]
  end

  defmodule A do
    use Normative

    defdata do
      a(type: String.t(), spec: is_binary, required: true)
      b(type: float(), default: 42.0)
    end
  end

  defmodule B do
    use Normative

    defdata do
      a(type: Struct.t(), schema: %Struct{a: spec(is_binary)})
    end
  end
end
