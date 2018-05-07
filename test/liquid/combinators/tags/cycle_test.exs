defmodule Liquid.Combinator.Tags.CycleTest do
  use ExUnit.Case

  import Liquid.Helpers
  alias Liquid.NimbleParser, as: Parser

  test "include tag parser" do
    test_combinator(
      "{% include 'snippet', my_variable: 'apples', my_other_variable: 'oranges' %}",
      &Parser.cycle/1,
      [{:include, [snippet_var: ["'snippet'"],
                   variable_atom: ["my_variable:"],
                   snippet_var: ["'apples'"],
                   variable_atom: ["my_other_variable:"],
                   snippet_var: ["'oranges'"]]}, ""]
    )
    test_combinator(
      "{% include 'pick_a_source' %}",
      &Parser.cycle/1,
      [{:include, [snippet_var: ["'pick_a_source'"]]}, ""]
    )
    # TODO: work with list
    # test_combinator(
    #   "{% include 'product' with products[0] %}",
    #   &Parser.include/1,
    #   [{:include, [snippet: ["'pick_a_source'"]]}, ""]
    # )

    test_combinator(
      "{% include 'product' with 'products' %}",
      &Parser.cycle/1,
      [{:include, [snippet_var: ["'product'"], snippet_var: ["'products'"]]}, ""]
    )
  end
end
