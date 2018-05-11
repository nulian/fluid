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
           variables: [variable_name: ["my_variable:"], value: "apples"],
           variables: [variable_name: ["my_other_variable:"], value: "oranges"]
         ]},
        ""
      ]
    )

    test_combinator_error(
      "{% include 'snippet' my_variable: 'apples', my_other_variable: 'oranges' %}",
      &Parser.include/1
    )

    test_combinator("{% include 'pick_a_source' %}", &Parser.include/1, [
      {:include, [snippet: ["'pick_a_source'"]]},
      ""
    ])

    test_combinator("{% include 'product' with products[0] %}", &Parser.include/1, [
      {:include, [snippet: ["'product'"], with_param: ["products[0]"]]},
      ""
    ])

    test_combinator("{% include 'product' with 'products' %}", &Parser.include/1, [
      {:include, [snippet: ["'product'"], with_param: ["products"]]},
      ""
    ])

    test_combinator("{% include 'product' for 'products' %}", &Parser.include/1, [
      {:include, [snippet: ["'product'"], for_param: ["products"]]},
      ""
    ])
  end
end
