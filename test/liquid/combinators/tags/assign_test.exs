defmodule Liquid.Combinators.Tags.AssignTest do
  use ExUnit.Case

  import Liquid.Helpers

  test "assign" do
    tags = [
      "{% assign cart = 5 %}",
      "{%      assign     cart    =    5    %}",
      "{%assign cart = 5%}",
      "{% assign cart=5 %}",
      "{%assign cart=5%}"
    ]

    Enum.each(tags, fn tag ->
      test_parse(
        tag,
        assign: [variable_name: "cart", value: 5]
      )
    end)

    test_parse(
      "{% assign cart = old_var %}",
      assign: [
        variable_name: "cart",
        value: {:variable, [parts: [part: "old_var"]]}
      ]
    )

    test_parse(
      "{% assign cart = 'empty cart' %}",
      assign: [variable_name: "cart", value: "empty cart"]
    )

    test_parse(
      ~s({% assign cart = "empty cart" %}),
      assign: [variable_name: "cart", value: "empty cart"]
    )
  end

  test "assign with variable" do
    test_parse(
      "{% assign cart = 5 %}{{ cart }}",
      assign: [variable_name: "cart", value: 5],
      liquid_variable: [variable: [parts: [part: "cart"]]]
    )
  end

  test "assign a list" do
    test_parse(
      "{% assign cart = product[0] %}",
      assign: [
        variable_name: "cart",
        value: {:variable, [parts: [part: "product", index: 0]]}
      ]
    )

    test_parse(
      "{% assign cart = products[0][0] %}",
      assign: [
        variable_name: "cart",
        value: {:variable, [parts: [part: "products", index: 0, index: 0]]}
      ]
    )

    test_parse(
      "{% assign cart = products[  0  ][ 0  ] %}",
      assign: [
        variable_name: "cart",
        value: {:variable, [parts: [part: "products", index: 0, index: 0]]}
      ]
    )
  end

  test "assign an object" do
    test_parse(
      "{% assign cart = company.employees.first.name %}",
      assign: [
        variable_name: "cart",
        value:
          {:variable,
           [
             parts: [
               part: "company",
               part: "employees",
               part: "first",
               part: "name"
             ]
           ]}
      ]
    )

    test_parse(
      "{% assign cart = company.managers[1].name %}",
      assign: [
        variable_name: "cart",
        value:
          {:variable,
           [
             parts: [
               part: "company",
               part: "managers",
               index: 1,
               part: "name"
             ]
           ]}
      ]
    )

    test_parse(
      "{% assign cart = company.managers[1][0].name %}",
      assign: [
        variable_name: "cart",
        value:
          {:variable,
           [
             parts: [
               part: "company",
               part: "managers",
               index: 1,
               index: 0,
               part: "name"
             ]
           ]}
      ]
    )
  end

  test "incorrect variable assignment" do
    test_combinator_error("{% assign cart@ = 5 %}")
    test_combinator_error("{% assign cart. = 5 %}")
    test_combinator_error("{% assign .cart = 5 %}")
  end
end
