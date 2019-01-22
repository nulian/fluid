defmodule Liquid.ParserTest do
  use ExUnit.Case
  alias Liquid.{Template, Tag, Block, Registers}
  import Liquid.Helpers

  test "only literal" do
    test_parse("Hello", ["Hello"])
  end

  test "liquid variable" do
    test_parse("{{ X }}", liquid_variable: [variable: [parts: [part: "X"]]])
  end

  test "test liquid open tag" do
    test_parse("{% assign a = 5 %}", assign: [variable_name: "a", value: 5])
  end

  test "test literal + liquid open tag" do
    test_parse("Hello {% assign a = 5 %}", ["Hello ", {:assign, [variable_name: "a", value: 5]}])
  end

  test "test liquid open tag + literal" do
    test_parse("{% assign a = 5 %} Hello", [{:assign, [variable_name: "a", value: 5]}, " Hello"])
  end

  test "test literal + liquid open tag + literal" do
    test_parse("Hello {% assign a = 5 %} Hello", [
      "Hello ",
      {:assign, [variable_name: "a", value: 5]},
      " Hello"
    ])
  end

  test "test multiple open tags" do
    test_parse("{% assign a = 5 %}{% increment a %}", [
      {:assign, [variable_name: "a", value: 5]},
      {:increment, [variable: [parts: [part: "a"]]]}
    ])
  end

  test "unclosed block must fails" do
    test_combinator_error(
      "{% capture variable %}",
      "Malformed tag, open without close: 'capture'"
    )
  end

  test "empty closed tag" do
    test_parse("{% capture variable %}{% endcapture %}", [
      {:capture, [variable_name: "variable", body: []]}
    ])
  end

  test "tag without open" do
    test_combinator_error(
      "{% if true %}{% endiif %}",
      "The 'if' tag has not been correctly closed"
    )
  end

  test "literal left, right and inside block" do
    test_parse("Hello{% capture variable %}World{% endcapture %}Here", [
      "Hello",
      {:capture, [variable_name: "variable", body: ["World"]]},
      "Here"
    ])
  end

  test "multiple closed tags" do
    test_parse(
      "Open{% capture first_variable %}Hey{% endcapture %}{% capture second_variable %}Hello{% endcapture %}{% capture last_variable %}{% endcapture %}Close",
      [
        "Open",
        {:capture, [variable_name: "first_variable", body: ["Hey"]]},
        {:capture, [variable_name: "second_variable", body: ["Hello"]]},
        {:capture, [variable_name: "last_variable", body: []]},
        "Close"
      ]
    )
  end

  test "tag inside block" do
    test_parse("{% capture x %}{% decrement x %}{% endcapture %}", [
      {:capture, [variable_name: "x", body: [{:decrement, [variable: [parts: [part: "x"]]]}]]}
    ])
  end

  test "literal and tag inside block" do
    test_parse("{% capture x %}X{% decrement x %}{% endcapture %}", [
      {:capture,
       [variable_name: "x", body: ["X", {:decrement, [variable: [parts: [part: "x"]]]}]]}
    ])
  end

  test "two tags inside block" do
    test_parse("{% capture x %}{% decrement x %}{% decrement x %}{% endcapture %}", [
      {:capture,
       [
         variable_name: "x",
         body: [
           {:decrement, [variable: [parts: [part: "x"]]]},
           {:decrement, [variable: [parts: [part: "x"]]]}
         ]
       ]}
    ])
  end

  test "tag inside block with tag ending" do
    test_parse(
      "{% capture x %}{% increment x %}{% endcapture %}{% decrement y %}",
      capture: [variable_name: "x", body: [increment: [variable: [parts: [part: "x"]]]]],
      decrement: [variable: [parts: [part: "y"]]]
    )
  end

  test "nested closed tags" do
    test_parse(
      "{% capture variable %}{% capture internal_variable %}{% endcapture %}{% endcapture %}",
      capture: [
        variable_name: "variable",
        body: [capture: [variable_name: "internal_variable", body: []]]
      ]
    )
  end

  test "block without endblock" do
    test_combinator_error("{% capture variable %}{% capture internal_variable %}{% endcapture %}")
  end

  test "block closed without open" do
    test_combinator_error(
      "{% endcapture %}",
      "The tag 'capture' was not opened"
    )
  end

  test "bad endblock" do
    test_combinator_error(
      "{% capture variable %}{% capture internal_variable %}{% endif %}{% endcapture %}"
    )
  end

  test "if block" do
    test_parse(
      "{% if a == b or c == d %}Hello{% endif %}",
      if: [
        conditions: [
          {:condition,
           {{:variable, [parts: [part: "a"]]}, :==, {:variable, [parts: [part: "b"]]}}},
          logical: [
            :or,
            {:condition,
             {{:variable, [parts: [part: "c"]]}, :==, {:variable, [parts: [part: "d"]]}}}
          ]
        ],
        body: ["Hello"]
      ]
    )
  end

  test "tablerow block" do
    test_parse(
      "{% tablerow item in array limit:2 %}{% endtablerow %}",
      tablerow: [
        statements: [
          variable: [parts: [part: "item"]],
          value: {:variable, [parts: [part: "array"]]},
          params: [limit: [2]]
        ],
        body: []
      ]
    )
  end

  test "unexpected outer else tag" do
    test_combinator_error(
      "{% else %}{% increment a %}",
      "Unexpected outer 'else' tag"
    )
  end

  test "else out of valid tag" do
    test_combinator_error(
      "{% capture z %}{% else %}{% endcapture %}",
      "capture does not expect else tag. The else tag is valid only inside: if, unless, case, for"
    )
  end

  test "for block with break and continue" do
    test_parse(
      "{%for i in array.items offset:continue limit:1000 %}{{i}}{%endfor%}",
      for: [
        statements: [
          variable: [parts: [part: "i"]],
          value: {:variable, [parts: [part: "array", part: "items"]]},
          params: [offset: ["continue"], limit: [1000]]
        ],
        body: [liquid_variable: [variable: [parts: [part: "i"]]]]
      ]
    )
  end

  test "for block with else" do
    test_parse(
      "{% for i in array %}x{% else %}y{% else %}z{% endfor %}",
      for: [
        statements: [
          variable: [parts: [part: "i"]],
          value: {:variable, [parts: [part: "array"]]},
          params: []
        ],
        body: ["x"],
        else: [body: ["y"]],
        else: [body: ["z"]]
      ]
    )
  end

  test "if block with elsif" do
    test_parse(
      "{% if a == b or c == d %}Hello{% elsif z > x %}bye{% endif %}",
      if: [
        conditions: [
          {:condition,
           {{:variable, [parts: [part: "a"]]}, :==, {:variable, [parts: [part: "b"]]}}},
          logical: [
            :or,
            {:condition,
             {{:variable, [parts: [part: "c"]]}, :==, {:variable, [parts: [part: "d"]]}}}
          ]
        ],
        body: ["Hello"],
        elsif: [
          conditions: [
            {:condition,
             {{:variable, [parts: [part: "z"]]}, :>, {:variable, [parts: [part: "x"]]}}}
          ],
          body: ["bye"]
        ]
      ]
    )
  end

  test "if block with several elsif" do
    test_parse(
      "{% if true %}Hello{% elsif true %}second{% decrement a %}third{% elsif false %}bye{% else %}clear{% endif %}",
      if: [
        conditions: [true],
        body: ["Hello"],
        elsif: [
          conditions: [true],
          body: ["second", {:decrement, [variable: [parts: [part: "a"]]]}, "third"]
        ],
        elsif: [conditions: [false], body: ["bye"]],
        else: [body: ["clear"]]
      ]
    )
  end

  test "multi blocks with subblocks" do
    test_parse(
      "{% if true %}{% if false %}One{% elsif true %}Two{% else %}Three{% endif %}{% endif %}{% if false %}Four{% endif %}",
      if: [
        conditions: [true],
        body: [
          if: [
            conditions: [false],
            body: ["One"],
            elsif: [
              conditions: [true],
              body: ["Two"]
            ],
            else: [
              body: ["Three"]
            ]
          ]
        ]
      ],
      if: [
        conditions: [false],
        body: ["Four"]
      ]
    )
  end

  test "multi blocks order" do
    test_parse(
      "{% assign a = 5 %}{% capture a %}body_a{% capture a_1 %}body_a_1{% endcapture %}{% endcapture %}{% capture b %}body_b{% endcapture %}",
      assign: [variable_name: "a", value: 5],
      capture: [
        variable_name: "a",
        body: ["body_a", {:capture, [variable_name: "a_1", body: ["body_a_1"]]}]
      ],
      capture: [variable_name: "b", body: ["body_b"]]
    )
  end

  test "multi tags" do
    test_parse(
      "{% decrement a %}{% increment b %}{% decrement c %}{% increment d %}",
      decrement: [variable: [parts: [part: "a"]]],
      increment: [variable: [parts: [part: "b"]]],
      decrement: [variable: [parts: [part: "c"]]],
      increment: [variable: [parts: [part: "d"]]]
    )
  end

  test "case block with when" do
    test_parse(
      "{% case x %}useless{% when x > 10 %}y{% when x > 1 %}z{% else %}A{% endcase %}",
      case: [
        conditions: [variable: [parts: [part: "x"]]],
        body: ["useless"],
        when: [
          conditions: [condition: {{:variable, [parts: [part: "x"]]}, :>, 10}],
          body: ["y"]
        ],
        when: [
          conditions: [condition: {{:variable, [parts: [part: "x"]]}, :>, 1}],
          body: ["z"]
        ],
        else: [body: ["A"]]
      ]
    )
  end

  defmodule MinusOneTag do
    def parse(%Tag{} = tag, %Template{} = context) do
      {tag, context}
    end

    def render(output, tag, context) do
      number = tag.markup |> Integer.parse() |> elem(0)
      {["#{number - 1}"] ++ output, context}
    end
  end

  defmodule MundoTag do
    def parse(%Tag{} = tag, %Template{} = context) do
      {tag, context}
    end

    def render(output, tag, context) do
      number = tag.markup |> Integer.parse() |> elem(0)
      {["#{number - 1}"] ++ output, context}
    end
  end

  setup_all do
    Registers.register("minus_one", MinusOneTag, Tag)
    Registers.register("Mundo", MundoTag, Block)
    Liquid.start()
    on_exit(fn -> Liquid.stop() end)
    :ok
  end

  test "custom tag from example(almost random now :)" do
    test_parse("{% minus_one  5 %}",
      custom: [{:custom_name, ["minus_one"]}, {:custom_markup, "5 "}]
    )
  end

  test "custom block from example(almost random now :)" do
    test_parse(
      "{% Mundo 5 %}my body{% endMundo %}",
      custom: [
        custom_name: ["Mundo"],
        custom_markup: "5 ",
        body: ["my body"]
      ]
    )
  end

  test "custom tag error" do
    test_combinator_error(
      "{% hola 5 %}",
      "Error processing tag 'hola'. It is malformed or you are creating a custom 'hola' without register it"
    )

    test_combinator_error(
      "{% hola %}body{% endhola a %}",
      "Error processing tag 'hola'. It is malformed or you are creating a custom 'hola' without register it"
    )

    test_combinator_error(
      "{% Mundo 10 %}body{% endMunda %}",
      "The 'Mundo' tag has not been correctly closed"
    )

    test_combinator_error(
      "{% Mundo 10 %}body",
      "Malformed tag, open without close: 'Mundo'"
    )
  end
end
