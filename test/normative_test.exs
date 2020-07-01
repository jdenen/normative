defmodule NormativeTest do
  use ExUnit.Case
  doctest Normative

  describe "defdata/1" do
    test "defines a struct from given fields" do
      assert %Test.A{} = %Test.A{a: "hi", b: 0.0}
    end

    test "defines s/0 function for Norm conformity" do
      schema = Test.A.s()

      assert %Norm.Core.Schema{specs: %{a: %Norm.Core.Spec{predicate: _}}} = schema

      assert {:ok, _} = Norm.conform(%Test.A{a: "hi"}, schema)
      assert {:error, _} = Norm.conform(%Test.A{a: :nope}, schema)
    end

    test "defines structs with defaults" do
      assert %Test.A{b: 42.0} = %Test.A{a: "hi"}
    end

    test "marks specific fields as required" do
      assert_raise ArgumentError, fn ->
        struct!(Test.A, b: 0.0)
      end
    end

    test "compiles with single line blocks" do
      assert %Test.B{} = %Test.B{a: "hi"}
    end

    test "defines s/0 function with schema fields" do
      schema = Test.B.s()

      assert %Norm.Core.Schema{
               specs: %{a: %Norm.Core.Schema{specs: %{a: %Norm.Core.Spec{predicate: _}}}}
             } = schema

      assert {:ok, _} = Norm.conform(%Test.B{a: %Test.Struct{a: "hi"}}, schema)
      assert {:error, _} = Norm.conform(%Test.B{a: "hi"}, schema)
    end
  end

  describe "new/1" do
    test "returns struct in OK tuple" do
      assert {:ok, %Test.A{}} = Test.A.new(a: "hi")
    end

    test "returns error tuple if struct fails compilation" do
      assert {:error, %ArgumentError{}} = Test.A.new(b: 1.0)
    end

    test "returns error tuple if struct fails Norm conformity" do
      assert {:error, [%{input: 42, path: [:a], spec: "is_binary()"}]} = Test.A.new(a: 42)
    end
  end
end
