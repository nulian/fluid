defmodule Liquid.Combinators.ExpressionTest do
  use ExUnit.Case
  import Liquid.Helpers
  alias Liquid.NimbleParser, as: Parser

  test "variable" do
    test_combiner("{{ xyz }}", &Parser.var/1, var: [literal: ["xyz "]])
  end
end
