defmodule Liquid.Combinators.ExpressionTest do
  use ExUnit.Case
  import Liquid.Helpers

  defmodule Parser do
    import NimbleParsec
    alias Liquid.Combinators.Expression

    defparsec(:start_tag, Expression.start_tag())
    defparsec(:end_tag, Expression.end_tag())
    defparsec(:start_var, Expression.start_var())
    defparsec(:end_var, Expression.end_var())
    defparsec(:var, Expression.var())
  end

  test "start_tag" do
    test_combiner("{%", &Parser.start_tag/1, [])
    test_combiner("{%   \t   \t", &Parser.start_tag/1, [])
  end

  test "end_tag" do
    test_combiner("%}", &Parser.end_tag/1, [])
    test_combiner("   \t   \t%}", &Parser.end_tag/1, [])
  end

  test "start_var" do
    test_combiner("{{", &Parser.start_var/1, [])
    test_combiner("{{   \t   \t", &Parser.start_var/1, [])
  end

  test "end_var" do
    test_combiner("}}", &Parser.end_var/1, [])
    test_combiner("   \t   \t}}", &Parser.end_var/1, [])
  end

  test "variable" do
    test_combiner("{{ xyz }}", &Parser.var/1, [var: [literal: ["xyz "]]])
  end
end
