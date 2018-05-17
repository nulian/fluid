defmodule Liquid.Combinators.Tags.CaseTest do
  use ExUnit.Case

  import Liquid.Helpers
  alias Liquid.NimbleParser, as: Parser

  test "case using multiples when" do
    test_combinator(
      "{% case condition %}{% when 1 %} its 1 {% when 2 %} its 2 {% endcase %}",
      &Parser.case/1,
      [
        {:case,
         [
           "condition",
           {:when, [1, {:output_text, ["its 1 "]}]},
           {:when, [2, {:output_text, ["its 2 "]}]}
         ]},
        ""
      ]
    )
  end

  test "case using a single when" do
    test_combinator(
      "{% case condition %}{% when \"string here\" %} hit {% endcase %}",
      &Parser.case/1,
      [
        {:case, ["condition", {:when, ["string here", {:output_text, ["hit "]}]}]},
        ""
      ]
    )
  end

  test "evaluate variables and expressions" do
    test_combinator("{% case a.size %}{% when 1 %}1{% when 2 %}2{% endcase %}", &Parser.case/1, [
      {:case,
       [
         "a.size",
         {:when, [1, {:output_text, ["1"]}]},
         {:when, [2, {:output_text, ["2"]}]}
       ]},
      ""
    ])
  end

  test "case with a else tag" do
    test_combinator(
      "{% case condition %}{% when 5 %} hit {% else %} else {% endcase %}",
      &Parser.case/1,
      [
        {:case,
         [
           "condition",
           {:when, [5, {:output_text, ["hit "]}]},
           {:else, [output_text: ["else "]]}
         ]},
        ""
      ]
    )
  end

  test "when tag with an or condition" do
    test_combinator(
      "{% case condition %}{% when 1 or 2 or 3 %} its 1 or 2 or 3 {% when 4 %} its 4 {% endcase %}",
      &Parser.case/1,
      [
        {:case,
         [
           "condition",
           {:when, [1, "or", 2, "or", 3, {:output_text, ["its 1 or 2 or 3 "]}]},
           {:when, [4, {:output_text, ["its 4 "]}]}
         ]},
        ""
      ]
    )
  end

  test "when with comma's" do
    test_combinator(
      "{% case condition %}{% when 1, 2, 3 %} its 1 or 2 or 3 {% when 4 %} its 4 {% endcase %}",
      &Parser.case/1,
      [
        {:case,
         [
           "condition",
           {:when, [1, ",", 2, ",", 3, {:output_text, ["its 1 or 2 or 3 "]}]},
           {:when, [4, {:output_text, ["its 4 "]}]}
         ]},
        ""
      ]
    )
  end

  test "when tag separated by commas and with different values" do
    test_combinator(
      "{% case condition %}{% when 1, \"string\", null %} its 1 or 2 or 3 {% when 4 %} its 4 {% endcase %}",
      &Parser.case/1,
      [
        {:case,
         [
           "condition",
           {:when,
            [
              1,
              ",",
              "string",
              ",",
              "null",
              {:output_text, ["its 1 or 2 or 3 "]}
            ]},
           {:when, [4, {:output_text, ["its 4 "]}]}
         ]},
        ""
      ]
    )
  end

  test "when tag with assign tag" do
    test_combinator(
      "{% case collection.handle %}{% when 'menswear-jackets' %}{% assign ptitle = 'menswear' %}{% when 'menswear-t-shirts' %}{% assign ptitle = 'menswear' %}{% else %} {% assign ptitle = 'womenswear' %}{% endcase %}",
      &Parser.case/1,
      [
        {:case,
         [
           "collection.handle",
           {:when,
            [
              "menswear-jackets",
              {:assign, [variable_name: "ptitle", value: "menswear"]},
              ""
            ]},
           {:when,
            [
              "menswear-t-shirts",
              {:assign, [variable_name: "ptitle", value: "menswear"]},
              ""
            ]},
           {:else,
            [
              {:assign, [variable_name: "ptitle", value: "womenswear"]},
              ""
            ]}
         ]},
        ""
      ]
    )
  end

  test "bad formed cases" do
    test_combinator_error(
      "{% case condition %}{% when 5 %} hit {% else %} else endcase %}",
      &Parser.case/1
    )

    test_combinator_error(
      "{% case condition %}{% when 5 %} hit {% else %} else {% endcas %}",
      &Parser.case/1
    )

    test_combinator_error(
      "{ case condition %}{% when 5 %} hit {% else %} else {% endcase %}",
      &Parser.case/1
    )

    test_combinator_error(
      "case condition %}{% when 5 %} hit {% else %} else {% endcase %}",
      &Parser.case/1
    )

    test_combinator_error(
      "{% casa condition %}{% when 5 %} hit {% else %} else {% endcase %}",
      &Parser.case/1
    )

    test_combinator_error(
      "{% case condition %}{% when 5 5 %} hit {% else %} else {% endcase %}",
      &Parser.case/1
    )

    test_combinator_error(
      "{% case condition %}{% when 5  %} hit {% els %} else {% endcase %}",
      &Parser.case/1
    )

    test_combinator_error(
      "{% case condition %}{% whene 5 %} hit {% else %} else {% endcase %}",
      &Parser.case/1
    )

    test_combinator_error(
      "{% case condition %}{% when 5 or %} hit {% else %} else {% endcase %}",
      &Parser.case/1
    )

    test_combinator_error(
      "{% case condition %}{% when 5  hit {% else %} else {% endcase %}",
      &Parser.case/1
    )

    test_combinator_error(
      "{% case condition condition condition2 %}{% when 5 %} hit {% else %} else {% endcase %}",
      &Parser.case/1
    )
  end
end
