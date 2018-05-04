defmodule Liquid.Combinator.Tags.AssignTest do
  use ExUnit.Case

  import Liquid.Helpers
  alias Liquid.NimbleParser, as: Parser

  test "assign" do
    test_combinator(
      "{% assign cart = 5 %}",
      &Parser.assign/1,
      [assign: [variable_name: "cart", value: 5], literal: [""]]
    )
  end
end
