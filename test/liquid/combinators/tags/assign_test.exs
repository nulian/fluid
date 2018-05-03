defmodule Liquid.Combinator.Tags.AssignTest do
  use ExUnit.Case

  import Liquid.Helpers
  alias Liquid.NimbleParser, as: Parser

  test "assign" do
    test_combinator(
      "assign cart = product",
      &Parser.assign/1,
      assign: [name: ["cart"], value: ["product"]]
    )
  end
end
