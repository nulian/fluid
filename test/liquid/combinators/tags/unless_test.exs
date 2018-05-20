defmodule Liquid.Combinators.Tags.UnlessTest do
  use ExUnit.Case

  import Liquid.Helpers
  alias Liquid.NimbleParser, as: Parser

  test "an unless using booleans " do
    test_combinator(
      "{% unless false %} this text should not go into the output {% endunless %}",
      &Parser.unless/1,
      [
        {:unless, ["false", " this text should not go into the output "]},
        ""
      ]
    )

    test_combinator(
      "{% unless true %} this text should go into the output {% endunless %}",
      &Parser.unless/1,
      [{:unless, ["true", " this text should go into the output "]}, ""]
    )
  end

  test "unless else " do
    test_combinator("{% unless \"foo\" %} YES {% else %} NO {% endunless %}", &Parser.unless/1, [
      {:unless, ["foo", " YES ", {:else, ["NO "]}]},
      ""
    ])
  end

  test "opening unless tag with multiple conditions " do
    test_combinator(
      "{% unless line_item.grams > 20000 and customer_address.city == 'Ottawa' or customer_address.city == 'Seatle' %}hello test{% endunless %}",
      &Parser.unless/1,
      [
        {:unless,
         [
           {:condition, ["line_item.grams", ">", 20000]},
           "and",
           {:condition, ["customer_address.city", "==", "Ottawa"]},
           "or",
           {:condition, ["customer_address.city", "==", "Seatle"]},
           "hello test"
         ]},
        ""
      ]
    )
  end

  test "using values" do
    test_combinator("{% unless a == true or b == 4 %} YES {% endunless %}", &Parser.unless/1, [
      {:unless,
       [
         {:condition, ["a", "==", "true"]},
         "or",
         {:condition, ["b", "==", 4]},
         " YES "
       ]},
      ""
    ])
  end

  test "parsing an awful markup" do
    awful_markup =
      "a == 'and' and b == 'or' and c == 'foo and bar' and d == 'bar or baz' and e == 'foo' and foo and bar"

    test_combinator("{% unless #{awful_markup} %} YES {% endunless %}", &Parser.unless/1, [
      {:unless,
       [
         {:condition, ["a", "==", "and"]},
         "and",
         {:condition, ["b", "==", "or"]},
         "and",
         {:condition, ["c", "==", "foo and bar"]},
         "and",
         {:condition, ["d", "==", "bar or baz"]},
         "and",
         {:condition, ["e", "==", "foo"]},
         "and",
         {:variable_name, "foo"},
         "and",
         {:variable_name, "bar"},
         " YES "
       ]},
      ""
    ])
  end

  test "nested unless" do
    test_combinator(
      "{% unless false %}{% unless false %} NO {% endunless %}{% endunless %}",
      &Parser.unless/1,
      [{:unless, ["false", "", {:unless, ["false", " NO "]}, ""]}, ""]
    )

    test_combinator(
      "{% unless false %}{% unless shipping_method.title == 'International Shipping' %}You're shipping internationally. Your order should arrive in 2–3 weeks.{% elsif shipping_method.title == 'Domestic Shipping' %}Your order should arrive in 3–4 days.{% else %} Thank you for your order!{% endunless %}{% endunless %}",
      &Parser.unless/1,
      [
        {:unless,
         [
           "false",
           "",
           {:unless,
            [
              {:condition, ["shipping_method.title", "==", "International Shipping"]},
              "You're shipping internationally. Your order should arrive in 2–3 weeks.",
              {:elsif,
               [
                 {:condition, ["shipping_method.title", "==", "Domestic Shipping"]},
                 "Your order should arrive in 3–4 days."
               ]},
              {:else, ["Thank you for your order!"]}
            ]},
           ""
         ]},
        ""
      ]
    )
  end

  test "comparing values" do
    test_combinator("{% unless null < 10 %} NO {% endunless %}", &Parser.unless/1, [
      {:unless, [{:condition, ["null", "<", 10]}, " NO "]},
      ""
    ])

    test_combinator("{% unless 10 < null %} NO {% endunless %}", &Parser.unless/1, [
      {:unless, [{:condition, [10, "<", "null"]}, " NO "]},
      ""
    ])
  end

  test "usisng contains" do
    test_combinator(
      "{% unless 'bob' contains 'f' %}yes{% else %}no{% endunless %}",
      &Parser.unless/1,
      [
        {:unless, [{:condition, ["bob", "contains", "f"]}, "yes", {:else, ["no"]}]},
        ""
      ]
    )
  end

  test "using elsif and else" do
    test_combinator(
      "{% unless shipping_method.title == 'International Shipping' %}You're shipping internationally. Your order should arrive in 2–3 weeks.{% elsif shipping_method.title == 'Domestic Shipping' %}Your order should arrive in 3–4 days.{% else %} Thank you for your order!{% endunless %}",
      &Parser.unless/1,
      [
        {:unless,
         [
           {:condition, ["shipping_method.title", "==", "International Shipping"]},
           "You're shipping internationally. Your order should arrive in 2–3 weeks.",
           {:elsif,
            [
              {:condition, ["shipping_method.title", "==", "Domestic Shipping"]},
              "Your order should arrive in 3–4 days."
            ]},
           {:else, ["Thank you for your order!"]}
         ]},
        ""
      ]
    )
  end

  test "2 else conditions in one unless" do
    test_combinator(
      "{% unless true %}test{% else %} a {% else %} b {% endunless %}",
      &Parser.unless/1,
      [{:unless, ["true", "test", {:else, ["a "]}, {:else, ["b "]}]}, ""]
    )
  end

  test "missing a opening tag and a closing tag" do
    test_combinator_error(" unless true %}test{% else %} a {% endunless %}", &Parser.unless/1)

    test_combinator_error("test{% else %} a {% endunless %}", &Parser.unless/1)

    test_combinator_error("{% unless true %}test{% else %} a ", &Parser.unless/1)

    test_combinator_error(" unless true %}test{% else  a {% endunless %}", &Parser.unless/1)

    test_combinator_error("{% unless true %}test{% else %} a  endunless %}", &Parser.unless/1)
  end
end
