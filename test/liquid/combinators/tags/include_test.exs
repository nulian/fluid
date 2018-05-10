defmodule Liquid.Combinator.Tags.IncludeTest do
  use ExUnit.Case

  import Liquid.Helpers
  alias Liquid.NimbleParser, as: Parser

  test "include tag parser" do
    test_combinator(
      "{% include 'snippet', my_variable: 'apples', my_other_variable: 'oranges' %}",
      &Parser.include/1,
      [
        {:include,
         [
           snippet: ["'snippet'"],
           variable_atom: ["my_variable:"],
           snippet: ["'apples'"],
           variable_atom: ["my_other_variable:"],
           snippet: ["'oranges'"]
         ]},
        ""
      ]
    )

    test_combinator_error(
      "{% include 'snippet' my_variable: 'apples', my_other_variable: 'oranges' %}",
      &Parser.include/1)

    test_combinator("{% include 'pick_a_source' %}", &Parser.include/1, [
      {:include, [snippet: ["'pick_a_source'"]]},
      ""
    ])

    # TODO: work with list
    # test_combinator(
    #   "{% include 'product' with products[0] %}",
    #   &Parser.include/1,
    #   [{:include, [snippet: ["'pick_a_source'"]]}, ""]
    # )

    test_combinator("{% include 'product' with 'products' %}", &Parser.include/1, [
      {:include, [snippet: ["'product'"], with_param: [snippet: ["'products'"]]]},
      ""
    ])

    test_combinator("{% include 'product' for 'products' %}", &Parser.include/1, [
      {:include, [snippet: ["'product'"], for_param: [snippet: ["'products'"]]]},
      ""
    ])
  end
end
