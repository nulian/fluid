defmodule Liquid.Combinators.Tags.CaseTest do
  use ExUnit.Case

  import Liquid.Helpers

  test "case using multiples when" do
    test_parse(
      "{% case condition %}{% when 1 %} its 1 {% when 2 %} its 2 {% endcase %}",
      case: [
        conditions: [variable: [parts: [part: "condition"]]],
        body: [],
        when: [conditions: [1], body: [" its 1 "]],
        when: [conditions: [2], body: [" its 2 "]]
      ]
    )
  end

  test "case using a single when" do
    test_parse(
      "{% case condition %}{% when \"string here\" %} hit {% endcase %}",
      case: [
        conditions: [variable: [parts: [part: "condition"]]],
        body: [],
        when: [conditions: ["string here"], body: [" hit "]]
      ]
    )
  end

  test "evaluate variables and expressions" do
    test_parse(
      "{% case a.size %}{% when 1 %}1{% when 2 %}2{% endcase %}",
      case: [
        conditions: [variable: [parts: [part: "a", part: "size"]]],
        body: [],
        when: [conditions: [1], body: ["1"]],
        when: [conditions: [2], body: ["2"]]
      ]
    )
  end

  test "case with body" do
    test_parse("{% case condition %} hit {% else %} else {% endcase %}",
      case: [
        {:conditions, [variable: [parts: [part: "condition"]]]},
        body: [" hit "],
        else: [body: [" else "]]
      ]
    )
  end

  test "case with a else tag" do
    test_parse(
      "{% case condition %}{% when 5 %} hit {% else %} else {% endcase %}",
      case: [
        conditions: [variable: [parts: [part: "condition"]]],
        body: [],
        when: [conditions: [5], body: [" hit "]],
        else: [body: [" else "]]
      ]
    )
  end

  test "when tag with an or condition" do
    test_parse(
      "{% case condition %}{% when 1 or 2 or 3 %} its 1 or 2 or 3 {% when 4 %} its 4 {% endcase %}",
      case: [
        conditions: [variable: [parts: [part: "condition"]]],
        body: [],
        when: [
          conditions: [1, {:logical, [:or, 2]}, {:logical, [:or, 3]}],
          body: [" its 1 or 2 or 3 "]
        ],
        when: [conditions: [4], body: [" its 4 "]]
      ]
    )
  end

  test "when with comma's" do
    test_parse(
      "{% case condition %}{% when 1, 2, 3 %} its 1 or 2 or 3 {% when 4 %} its 4 {% endcase %}",
      case: [
        conditions: [variable: [parts: [part: "condition"]]],
        body: [],
        when: [
          conditions: [1, {:logical, [:or, 2]}, {:logical, [:or, 3]}],
          body: [" its 1 or 2 or 3 "]
        ],
        when: [conditions: [4], body: [" its 4 "]]
      ]
    )
  end

  test "when tag separated by commas and with different values" do
    test_parse(
      "{% case condition %}{% when 1, \"string\", null %} its 1 or 2 or 3 {% when 4 %} its 4 {% endcase %}",
      case: [
        conditions: [variable: [parts: [part: "condition"]]],
        body: [],
        when: [
          conditions: [
            1,
            {:logical, [:or, "string"]},
            {:logical, [:or, nil]}
          ],
          body: [" its 1 or 2 or 3 "]
        ],
        when: [conditions: [4], body: [" its 4 "]]
      ]
    )
  end

  test "when tag with assign tag" do
    test_parse(
      "{% case collection.handle %}{% when 'menswear-jackets' %}{% assign ptitle = 'menswear' %}{% when 'menswear-t-shirts' %}{% assign ptitle = 'menswear' %}{% else %}{% assign ptitle = 'womenswear' %}{% endcase %}",
      case: [
        conditions: [variable: [parts: [part: "collection", part: "handle"]]],
        body: [],
        when: [
          conditions: ["menswear-jackets"],
          body: [
            assign: [
              variable_name: "ptitle",
              value: "menswear"
            ]
          ]
        ],
        when: [
          conditions: ["menswear-t-shirts"],
          body: [
            assign: [
              variable_name: "ptitle",
              value: "menswear"
            ]
          ]
        ],
        else: [
          body: [
            assign: [
              variable_name: "ptitle",
              value: "womenswear"
            ]
          ]
        ]
      ]
    )
  end

  test "bad formed cases" do
    test_combinator_error("{% case condition %}{% when 5 %} hit {% else %} else endcase %}")

    test_combinator_error("{% case condition %}{% when 5 %} hit {% else %} else {% endcas %}")

    test_combinator_error("{ case condition %}{% when 5 %} hit {% else %} else {% endcase %}")

    test_combinator_error("case condition %}{% when 5 %} hit {% else %} else {% endcase %}")

    test_combinator_error("{% casa condition %}{% when 5 %} hit {% else %} else {% endcase %}")

    test_combinator_error("{% case condition %}{% when 5 5 %} hit {% else %} else {% endcase %}")

    test_combinator_error("{% case condition %}{% when 5 or %} hit {% else %} else {% endcase %}")

    test_combinator_error("{% case condition %}{% when 5  hit {% else %} else {% endcase %}")

    test_combinator_error(
      "{% case condition condition condition2 %}{% when 5 %} hit {% else %} else {% endcase %}"
    )
  end
end
