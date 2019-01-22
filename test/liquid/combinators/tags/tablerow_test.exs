defmodule Liquid.Combinators.Tags.TablerowTest do
  use ExUnit.Case

  import Liquid.Helpers

  test "tablerow tag: basic tag structures" do
    tags = [
      "{% tablerow item in array %}{% endtablerow %}",
      "{%tablerow item in array%}{%endtablerow%}",
      "{%     tablerow     item    in     array    %}{%    endtablerow    %}"
    ]

    Enum.each(tags, fn tag ->
      test_parse(
        tag,
        tablerow: [
          statements: [
            variable: [parts: [part: "item"]],
            value: {:variable, [parts: [part: "array"]]},
            params: []
          ],
          body: []
        ]
      )
    end)
  end

  test "tablerow tag: limit parameter" do
    tags = [
      "{% tablerow item in array limit:2 %}{% endtablerow %}",
      "{%tablerow item in array limit:2%}{%endtablerow%}",
      "{%     tablerow     item    in     array  limit:2  %}{%    endtablerow    %}",
      "{%     tablerow    item    in     array  limit: 2  %}{%    endtablerow    %}"
    ]

    Enum.each(tags, fn tag ->
      test_parse(
        tag,
        tablerow: [
          statements: [
            variable: [parts: [part: "item"]],
            value: {:variable, [parts: [part: "array"]]},
            params: [limit: [2]]
          ],
          body: []
        ]
      )
    end)
  end

  test "tablerow tag: offset parameter" do
    tags = [
      "{% tablerow item in array offset:2 %}{% endtablerow %}",
      "{%tablerow item in array offset:2%}{%endtablerow%}",
      "{%     tablerow     item    in     array  offset:2  %}{%    endtablerow    %}"
    ]

    Enum.each(tags, fn tag ->
      test_parse(
        tag,
        tablerow: [
          statements: [
            variable: [parts: [part: "item"]],
            value: {:variable, [parts: [part: "array"]]},
            params: [offset: [2]]
          ],
          body: []
        ]
      )
    end)
  end

  test "tablerow tag: cols parameter" do
    tags = [
      "{% tablerow item in array cols:2 %}{% endtablerow %}",
      "{%tablerow item in array cols:2%}{%endtablerow%}",
      "{%     tablerow     item    in     array  cols:2  %}{%    endtablerow    %}"
    ]

    Enum.each(tags, fn tag ->
      test_parse(
        tag,
        tablerow: [
          statements: [
            variable: [parts: [part: "item"]],
            value: {:variable, [parts: [part: "array"]]},
            params: [cols: [2]]
          ],
          body: []
        ]
      )
    end)
  end

  test "tablerow tag: range parameter" do
    tags = [
      "{% tablerow i in (1..10) %}{{ i }}{% endtablerow %}",
      "{%tablerow i in (1..10)%}{{ i }}{% endtablerow %}",
      "{%     tablerow     i     in     (1..10)      %}{{ i }}{%     endtablerow     %}"
    ]

    Enum.each(tags, fn tag ->
      test_parse(
        tag,
        tablerow: [
          statements: [
            variable: [parts: [part: "i"]],
            value: {:range, [start: 1, end: 10]},
            params: []
          ],
          body: [
            liquid_variable: [variable: [parts: [part: "i"]]]
          ]
        ]
      )
    end)
  end

  test "tablerow tag: range with variables" do
    test_parse(
      "{% tablerow i in (my_var..10) %}{{ i }}{% endtablerow %}",
      tablerow: [
        statements: [
          variable: [parts: [part: "i"]],
          value: {:range, [start: {:variable, [parts: [part: "my_var"]]}, end: 10]},
          params: []
        ],
        body: [
          liquid_variable: [variable: [parts: [part: "i"]]]
        ]
      ]
    )
  end

  test "tablerow tag: call with 2 parameters" do
    test_parse(
      "{% tablerow i in (my_var..10) limit:2 cols:2 %}{{ i }}{% endtablerow %}",
      tablerow: [
        statements: [
          variable: [parts: [part: "i"]],
          value: {:range, [start: {:variable, [parts: [part: "my_var"]]}, end: 10]},
          params: [limit: [2], cols: [2]]
        ],
        body: [
          liquid_variable: [variable: [parts: [part: "i"]]]
        ]
      ]
    )
  end

  test "tablerow tag: invalid tag structure and variable values" do
    test_combinator_error(
      "{% tablerow i in (my_var..10) %}{{ i }}{% else %}{% else %}{% endtablerow %}"
    )

    test_combinator_error(
      "{% tablerow i in (my_var..product.title[2]) %}{{ i }}{% else %}{% endtablerow %}"
    )

    test_combinator_error(
      "{% tablerow i in products limit: a %}{{ i }}{% else %}{% endtablerow %}"
    )
  end
end
