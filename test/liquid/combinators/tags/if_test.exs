defmodule Liquid.Combinators.Tags.IfTest do
  use ExUnit.Case

  import Liquid.Helpers
  alias Liquid.NimbleParser, as: Parser

  test "an if using booleans " do
    test_combinator(
      "{% if false %} this text should not go into the output {% endif %}",
      &Parser.if/1,
      [{:if, ["false", " this text should not go into the output "]}]
    )

    test_combinator(
      "{% if true %} this text should go into the output {% endif %}",
      &Parser.if/1,
      [{:if, ["true", " this text should go into the output "]}]
    )
  end

  test "if else " do
    test_combinator("{% if \"foo\" %} YES {% else %} NO {% endif %}", &Parser.if/1, [
      {:if, ["foo", " YES ", {:else, [" NO "]}]}
    ])
  end

  test "opening if tag with multiple conditions " do
    test_combinator(
      "{% if line_item.grams > 20000 and customer_address.city == 'Ottawa' or customer_address.city == 'Seatle' %}hello test{% endif %}",
      &Parser.if/1,
      if: [
        {:condition, [{:variable, ["line_item", "grams"]}, ">", 20000]},
        "and",
        {:condition, [{:variable, ["customer_address", "city"]}, "==", "Ottawa"]},
        "or",
        {:condition, [{:variable, ["customer_address", "city"]}, "==", "Seatle"]},
        "hello test"
      ]
    )
  end

  test "using values" do
    test_combinator("{% if a == true or b == 4 %} YES {% endif %}", &Parser.if/1, [
      {:if,
       [
         {:condition, [{:variable, ["a"]}, "==", true]},
         "or",
         {:condition, [{:variable, ["b"]}, "==", 4]},
         " YES "
       ]}
    ])
  end

  test "parsing an awful markup" do
    awful_markup =
      "a == 'and' and b == 'or' and c == 'foo and bar' and d == 'bar or baz' and e == 'foo' and foo and bar"

    test_combinator(
      "{% if #{awful_markup} %} YES {% endif %}",
      &Parser.if/1,
      if: [
        {:condition, [{:variable, ["a"]}, "==", "and"]},
        "and",
        {:condition, [{:variable, ["b"]}, "==", "or"]},
        "and",
        {:condition, [{:variable, ["c"]}, "==", "foo and bar"]},
        "and",
        {:condition, [{:variable, ["d"]}, "==", "bar or baz"]},
        "and",
        {:condition, [{:variable, ["e"]}, "==", "foo"]},
        "and",
        {:variable_name, "foo"},
        "and",
        {:variable_name, "bar"},
        " YES "
      ]
    )
  end

  test "nested if" do
    test_combinator("{% if false %}{% if false %} NO {% endif %}{% endif %}", &Parser.if/1, [
      {:if, ["false", {:if, ["false", " NO "]}]}
    ])

    test_combinator(
      "{% if false %}{% if shipping_method.title == 'International Shipping' %}You're shipping internationally. Your order should arrive in 2–3 weeks.{% elsif shipping_method.title == 'Domestic Shipping' %}Your order should arrive in 3–4 days.{% else %} Thank you for your order!{% endif %}{% endif %}",
      &Parser.if/1,
      if: [
        "false",
        {:if,
         [
           {:condition,
            [
              {:variable, ["shipping_method", "title"]},
              "==",
              "International Shipping"
            ]},
           "You're shipping internationally. Your order should arrive in 2–3 weeks.",
           {:elsif,
            [
              {:condition,
               [
                 {:variable, ["shipping_method", "title"]},
                 "==",
                 "Domestic Shipping"
               ]},
              "Your order should arrive in 3–4 days."
            ]},
           {:else, [" Thank you for your order!"]}
         ]}
      ]
    )
  end

  test "comparing values" do
    test_combinator("{% if null < 10 %} NO {% endif %}", &Parser.if/1, [
      {:if, [{:condition, [nil, "<", 10]}, " NO "]}
    ])

    test_combinator("{% if 10 < null %} NO {% endif %}", &Parser.if/1, [
      {:if, [{:condition, [10, "<", nil]}, " NO "]}
    ])
  end

  test "usisng contains" do
    test_combinator(
      "{% if 'bob' contains 'f' %}yes{% else %}no{% endif %}",
      &Parser.if/1,
      if: [
        {:condition, ["bob", "contains", "f"]},
        "yes",
        {:else, ["no"]}
      ]
    )
  end

  test "using elsif and else" do
    test_combinator(
      "{% if shipping_method.title == 'International Shipping' %}You're shipping internationally. Your order should arrive in 2–3 weeks.{% elsif shipping_method.title == 'Domestic Shipping' %}Your order should arrive in 3–4 days.{% else %} Thank you for your order!{% endif %}",
      &Parser.if/1,
      if: [
        {:condition,
         [
           {:variable, ["shipping_method", "title"]},
           "==",
           "International Shipping"
         ]},
        "You're shipping internationally. Your order should arrive in 2–3 weeks.",
        {:elsif,
         [
           {:condition,
            [
              {:variable, ["shipping_method", "title"]},
              "==",
              "Domestic Shipping"
            ]},
           "Your order should arrive in 3–4 days."
         ]},
        {:else, [" Thank you for your order!"]}
      ]
    )
  end

  test "2 else conditions in one if" do
    test_combinator("{% if true %}test{% else %} a {% else %} b {% endif %}", &Parser.if/1, [
      {:if, ["true", "test", {:else, [" a "]}, {:else, [" b "]}]}
    ])
  end

  test "missing a opening tag and a closing tag" do
    test_combinator_error(" if true %}test{% else %} a {% endif %}", &Parser.if/1)

    test_combinator_error("test{% else %} a {% endif %}", &Parser.if/1)

    test_combinator_error("{% if true %}test{% else %} a ", &Parser.if/1)

    test_combinator_error(" if true %}test{% else  a {% endif %}", &Parser.if/1)

    test_combinator_error("{% if true %}test{% else %} a  endif %}", &Parser.if/1)
  end
end
