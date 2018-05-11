defmodule Liquid.Combinator.Tags.AssignTest do
  use ExUnit.Case

  import Liquid.Helpers
  alias Liquid.NimbleParser, as: Parser

  test "assign" do
    tags = [
      "{% assign cart = 5 %}",
      "{%      assign     cart    =    5    %}",
      "{%assign cart = 5%}",
      "{% assign cart=5 %}",
      "{%assign cart=5%}"
    ]

    Enum.each(tags, fn tag ->
      test_combinator(tag, &Parser.assign/1, [
        {:assign, [variable_name: "cart", value: 5]},
        ""
      ])
    end)

  end

  test "assign a list" do
    test_combinator("{% assign cart = product[0] %}", &Parser.assign/1, [
                      {:assign, [variable_name: "cart", value: "product[0]"]},
                      ""
                    ])

    test_combinator("{% assign cart = products[0][0] %}", &Parser.assign/1, [
                      {:assign, [variable_name: "cart", value: "products[0][0]"]},
                      ""
                    ])

    test_combinator("{% assign cart = products[  0  ][ 0  ] %}", &Parser.assign/1, [
                      {:assign, [variable_name: "cart", value: "products[0][0]"]},
                      ""
                    ])
  end

  @tag :skip
  test "assign an object" do
    test_combinator("{% assign var = company.name %} Hello {{ var }}", &Parser.assign/1, [
      {:assign, [variable_name: "var", value: "company.name"]},
      ""
    ])

    test_combinator(
      "{% assign var = company.managers[1].name %} Hello {{ var }}",
      &Parser.assign/1,
      [
        {:assign, [variable_name: "cart", value: "product[0]"]},
        ""
      ]
    )
  end

  test "incorrect variable assignation" do
    test_combinator_error("{% assign cart@ = 5 %}", &Parser.assign/1)
    test_combinator_error("{% assign cart. = 5 %}", &Parser.assign/1)
    test_combinator_error("{% assign .cart = 5 %}", &Parser.assign/1)
    test_combinator_error("{% assign cart? = 5 %}", &Parser.assign/1)
  end
end
