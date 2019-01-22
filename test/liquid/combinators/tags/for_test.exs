defmodule Liquid.Combinators.Tags.ForTest do
  use ExUnit.Case

  import Liquid.Helpers

  test "for tag: basic tag structures" do
    tags = [
      "{% for item in array %}{% endfor %}",
      "{%for item in array%}{%endfor%}",
      "{%     for     item    in     array    %}{%    endfor    %}"
    ]

    Enum.each(tags, fn tag ->
      test_parse(
        tag,
        for: [
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

  test "for tag: else tag structures" do
    tags = [
      "{% for item in array %}{% else %}{% endfor %}",
      "{%for item in array%}{%else%}{%endfor%}",
      "{%     for     item    in     array    %}{%   else    %}{%    endfor    %}"
    ]

    Enum.each(tags, fn tag ->
      test_parse(
        tag,
        for: [
          statements: [
            variable: [parts: [part: "item"]],
            value: {:variable, [parts: [part: "array"]]},
            params: []
          ],
          body: [],
          else: [body: []]
        ]
      )
    end)
  end

  test "for tag: limit parameter" do
    tags = [
      "{% for item in array limit:2 %}{% else %}{% endfor %}",
      "{%for item in array limit:2%}{%else%}{%endfor%}",
      "{%     for     item    in     array  limit:2  %}{%   else    %}{%    endfor    %}",
      "{%     for     item    in     array  limit: 2  %}{%   else    %}{%    endfor    %}"
    ]

    Enum.each(tags, fn tag ->
      test_parse(
        tag,
        for: [
          statements: [
            variable: [parts: [part: "item"]],
            value: {:variable, [parts: [part: "array"]]},
            params: [limit: [2]]
          ],
          body: [],
          else: [body: []]
        ]
      )
    end)
  end

  test "for tag: offset parameter" do
    tags = [
      "{% for item in array offset:2 %}{% else %}{% endfor %}",
      "{%for item in array offset:2%}{%else%}{%endfor%}",
      "{%     for     item    in     array  offset:2  %}{%   else    %}{%    endfor    %}"
    ]

    Enum.each(tags, fn tag ->
      test_parse(
        tag,
        for: [
          statements: [
            variable: [parts: [part: "item"]],
            value: {:variable, [parts: [part: "array"]]},
            params: [offset: [2]]
          ],
          body: [],
          else: [body: []]
        ]
      )
    end)
  end

  test "for tag: reversed parameter" do
    tags = [
      "{% for item in array reversed %}{% else %}{% endfor %}",
      "{%for item in array reversed%}{%else%}{%endfor%}",
      "{%     for     item    in     array  reversed  %}{%   else    %}{%    endfor    %}"
    ]

    Enum.each(tags, fn tag ->
      test_parse(
        tag,
        for: [
          statements: [
            variable: [parts: [part: "item"]],
            value: {:variable, [parts: [part: "array"]]},
            params: [reversed: []]
          ],
          body: [],
          else: [body: []]
        ]
      )
    end)
  end

  test "for tag: range parameter" do
    tags = [
      "{% for i in (1..10) %}{{ i }}{% endfor %}",
      "{%for i in (1..10)%}{{ i }}{% endfor %}",
      "{%     for     i     in     (1..10)      %}{{ i }}{%     endfor     %}"
    ]

    Enum.each(tags, fn tag ->
      test_parse(
        tag,
        for: [
          statements: [
            variable: [parts: [part: "i"]],
            value: {:range, [start: 1, end: 10]},
            params: []
          ],
          body: [liquid_variable: [variable: [parts: [part: "i"]]]]
        ]
      )
    end)
  end

  test "for tag: range with variables" do
    test_parse(
      "{% for i in (my_var..10) %}{{ i }}{% endfor %}",
      for: [
        statements: [
          variable: [parts: [part: "i"]],
          value: {:range, [start: {:variable, [parts: [part: "my_var"]]}, end: 10]},
          params: []
        ],
        body: [liquid_variable: [variable: [parts: [part: "i"]]]]
      ]
    )
  end

  test "for tag: break tag" do
    test_parse(
      "{% for i in (my_var..10) %}{{ i }}{% break %}{% endfor %}",
      for: [
        statements: [
          variable: [parts: [part: "i"]],
          value: {:range, [start: {:variable, [parts: [part: "my_var"]]}, end: 10]},
          params: []
        ],
        body: [
          liquid_variable: [variable: [parts: [part: "i"]]],
          break: []
        ]
      ]
    )
  end

  test "for tag: continue tag" do
    test_parse(
      "{% for i in (1..my_var) %}{{ i }}{% continue %}{% endfor %}",
      for: [
        statements: [
          variable: [parts: [part: "i"]],
          value: {:range, [start: 1, end: {:variable, [parts: [part: "my_var"]]}]},
          params: []
        ],
        body: [
          liquid_variable: [variable: [parts: [part: "i"]]],
          continue: []
        ]
      ]
    )
  end
end
