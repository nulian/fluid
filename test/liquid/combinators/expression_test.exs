defmodule Liquid.Combinators.ExpressionTest do
  use ExUnit.Case
  import Liquid.Helpers

  defmodule Parser do
    import NimbleParsec
    alias Liquid.Combinators.Expression

    defparsec(:var, Expression.var())
    defparsec(:tag, Expression.tag())
  end

  test "variable" do
    test_combiner("{{ xyz }}", &Parser.var/1, [var: [literal: ["xyz "]]])
  end

  test "tag" do
    test_combiner("{% xyz %}", &Parser.tag/1, [tag: [literal: ["xyz "]]])
  end
end
