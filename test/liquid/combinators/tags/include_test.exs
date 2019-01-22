defmodule Liquid.Combinators.Tags.IncludeTest do
  use ExUnit.Case

  import Liquid.Helpers

  test "include tag parser" do
    test_parse(
      "{% include 'snippet', my_variable: 'apples', my_other_variable: 'oranges' %}",
      include: [
        variable_name: "snippet",
        params: [
          assignment: [variable_name: "my_variable", value: "apples"],
          assignment: [variable_name: "my_other_variable", value: "oranges"]
        ]
      ]
    )

    test_parse(
      "{% include 'snippet' my_variable: 'apples', my_other_variable: 'oranges' %}",
      include: [
        variable_name: "snippet",
        params: [
          assignment: [variable_name: "my_variable", value: "apples"],
          assignment: [variable_name: "my_other_variable", value: "oranges"]
        ]
      ]
    )

    test_parse(
      "{% include 'pick_a_source' %}",
      include: [variable_name: "pick_a_source"]
    )

    test_parse(
      "{% include 'product' with products[0] %}",
      include: [
        variable_name: "product",
        with: [
          variable: [parts: [part: "products", index: 0]]
        ]
      ]
    )

    test_parse(
      "{% include 'product' with 'products' %}",
      include: [variable_name: "product", with: ["products"]]
    )

    test_parse(
      "{% include 'product' for 'products' %}",
      include: [variable_name: "product", for: ["products"]]
    )
  end
end
