defmodule NormativeTest do
  use ExUnit.Case
  doctest Normative

  describe "defdata/1" do
    test "defines a struct from given fields" do
      assert %Test.A{} = %Test.A{a: "hi", b: 0.0}
    end

    test "sets internal version field" do
      assert %Test.A{__vsn__: 1} = %Test.A{a: "hi"}
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
      assert {:ok, %Test.A{__vsn__: 1}} = Test.A.new(a: "hi")
    end

    test "allows internal version to be overwritten" do
      assert {:ok, %Test.A{__vsn__: 42}} = Test.A.new(__vsn__: 42, a: "hi")
    end

    test "returns error tuple if struct fails Norm conformity" do
      assert {:error, [%{input: 42, path: [:a], spec: "is_binary()"}]} = Test.A.new(a: 42)
    end
  end

  describe "migrate/2" do
    test "executes user-defined callback when version qualifies" do
      assert {:ok, %Test.Migrate{__vsn__: 2, a: "42"}} = Test.Migrate.new(__vsn__: 1, a: 42)
    end

    test "passes through without version match" do
      assert {:ok, %Test.Migrate{__vsn__: 3, a: "hi"}} = Test.Migrate.new(__vsn__: 3, a: "hi")
    end

    test "migrated data is conformed" do
      assert {:error, [%{input: 42, path: [:a], spec: "is_binary()"}]} =
               Test.Migrate.new(__vsn__: 3, a: 42)
    end
  end
end
