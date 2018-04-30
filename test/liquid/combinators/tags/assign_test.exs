defmodule Liquid.Combinator.Tags.AssignTest do
  use ExUnit.Case

  import Liquid.Helpers

  defmodule Parser do
    import NimbleParsec
    alias Liquid.Combinators.Tags.Assign

    defparsec(:assign, Assign.definition())
  end

  test "assign" do
    test_combiner("assign cart = product", &Parser.assign/1,
      [assign: [name: ["cart"], value: ["product"]]])
  end
end
