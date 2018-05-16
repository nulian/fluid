defmodule Liquid.Combinator.Tags.UnlessTest do
  use ExUnit.Case

  import Liquid.Helpers
  alias Liquid.NimbleParser, as: Parser

  test "an unless using booleans " do
    test_combinator(
      "{% unless false %} this text should not go into the output {% endunless %}",
      &Parser.unless/1,
      [
        {:unless,
         [
           "false",
           {:output_text, [" this text should not go into the output "]}
         ]},
        ""
      ]
    )

    test_combinator(
      "{% unless true %} this text should go into the output {% endunless %}",
      &Parser.unless/1,
      [
        {:unless,
         [
           "true",
           {:output_text, [" this text should go into the output "]}
         ]},
        ""
      ]
    )
  end

  test "unless else " do
    test_combinator("{% unless \"foo\" %} YES {% else %} NO {% endunless %}", &Parser.unless/1, [
      {:unless,
       [
         "foo",
         {:output_text, [" YES "]},
         {:else, [output_text: ["NO "]]}
       ]},
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
           {:output_text, ["hello test"]}
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
         {:output_text, [" YES "]}
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
         {:output_text, [" YES "]}
       ]},
      ""
    ])
  end

  test "nested unless" do
    test_combinator(
      "{% unless false %}{% unless false %} NO {% endunless %}{% endunless %}",
      &Parser.unless/1,
      [
        {:unless,
         [
           "false",
           {:output_text, [""]},
           {:unless, ["false", {:output_text, [" NO "]}]},
           ""
         ]},
        ""
      ]
    )

    test_combinator(
      "{% unless false %}{% unless shipping_method.title == 'International Shipping' %}You're shipping internationally. Your order should arrive in 2–3 weeks.{% elsif shipping_method.title == 'Domestic Shipping' %}Your order should arrive in 3–4 days.{% else %} Thank you for your order!{% endunless %}{% endunless %}",
      &Parser.unless/1,
      [
        {:unless,
         [
           "false",
           {:output_text, [""]},
           {:unless,
            [
              condition: ["shipping_method.title", "==", "International Shipping"],
              output_text: [
                "You're shipping internationally. Your order should arrive in 2–3 weeks."
              ],
              elsif: [
                condition: ["shipping_method.title", "==", "Domestic Shipping"],
                output_text: ["Your order should arrive in 3–4 days."]
              ],
              else: [output_text: ["Thank you for your order!"]]
            ]},
           ""
         ]},
        ""
      ]
    )
  end

  test "comparing values" do
    test_combinator("{% unless null < 10 %} NO {% endunless %}", &Parser.unless/1, [
      {:unless, [condition: ["null", "<", 10], output_text: [" NO "]]},
      ""
    ])

    test_combinator("{% unless 10 < null %} NO {% endunless %}", &Parser.unless/1, [
      {:unless, [condition: [10, "<", "null"], output_text: [" NO "]]},
      ""
    ])
  end

  test "usisng contains" do
    test_combinator(
      "{% unless 'bob' contains 'f' %}yes{% else %}no{% endunless %}",
      &Parser.unless/1,
      [
        {:unless,
         [
           condition: ["bob", "contains", "f"],
           output_text: ["yes"],
           else: [output_text: ["no"]]
         ]},
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
           condition: ["shipping_method.title", "==", "International Shipping"],
           output_text: [
             "You're shipping internationally. Your order should arrive in 2–3 weeks."
           ],
           elsif: [
             condition: ["shipping_method.title", "==", "Domestic Shipping"],
             output_text: ["Your order should arrive in 3–4 days."]
           ],
           else: [output_text: ["Thank you for your order!"]]
         ]},
        ""
      ]
    )
  end

  test "2 else conditions in one unless" do
    test_combinator(
      "{% unless true %}test{% else %} a {% else %} b {% endunless %}",
      &Parser.unless/1,
      [
        {:unless,
         [
           "true",
           {:output_text, ["test"]},
           {:else, [output_text: ["a "]]},
           {:else, [output_text: ["b "]]}
         ]},
        ""
      ]
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
