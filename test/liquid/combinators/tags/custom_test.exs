defmodule Liquid.Combinators.Tags.CustomTest do
  use ExUnit.Case
  import Liquid.Helpers
  alias Liquid.{Tag, Block, Registers}

  defmodule MyCustomTag do
    def render(output, tag, context) do
      {"MyCustomTag Results...output:#{output} tag:#{tag}", context}
    end
  end

  defmodule MyCustomBlock do
    def render(output, tag, context) do
      {"MyCustomBlock Results...output:#{output} tag:#{tag}", context}
    end
  end

  setup_all do
    Registers.register("MyCustomTag", MyCustomTag, Tag)
    Registers.register("MyCustomBlock", MyCustomBlock, Block)
    Liquid.start()
    on_exit(fn -> Liquid.stop() end)
    :ok
  end

  test "custom tags: basic tag structures" do
    tags = [
      {"{% MyCustomTag             argument = 1 %}",
       [
         custom: [
           {:custom_name, ["MyCustomTag"]},
           {:custom_markup, "argument = 1 "}
         ]
       ]},
      {"{%MyCustomTag  argument = 1%}",
       [
         custom: [
           {:custom_name, ["MyCustomTag"]},
           {:custom_markup, "argument = 1"}
         ]
       ]},
      {"{% MyCustomTag             argument            =            1        %}",
       [
         custom: [
           {:custom_name, ["MyCustomTag"]},
           {:custom_markup, "argument            =            1        "}
         ]
       ]}
    ]

    Enum.each(tags, fn {tag, expected} ->
      test_parse(tag, expected)
    end)
  end

  test "custom blocks: basic blocks structures" do
    tags = [
      {"{% MyCustomBlock             argument = 1 %}{% if true %}this is true{% endif %}{% endMyCustomBlock %}",
       [
         custom: [
           custom_name: ["MyCustomBlock"],
           custom_markup: "argument = 1 ",
           body: [if: [conditions: [true], body: ["this is true"]]]
         ]
       ]},
      {"{%MyCustomBlock  argument = 1%}{%endMyCustomBlock%}",
       [
         custom: [
           custom_name: ["MyCustomBlock"],
           custom_markup: "argument = 1",
           body: []
         ]
       ]},
      {"{% MyCustomBlock            argument            =            1        %}{%      endMyCustomBlock      %}",
       [
         custom: [
           custom_name: ["MyCustomBlock"],
           custom_markup: "argument            =            1        ",
           body: []
         ]
       ]}
    ]

    Enum.each(tags, fn {tag, expected} ->
      test_parse(tag, expected)
    end)
  end

  test "nested custom blocks and tags" do
    tag =
      "{% MyCustomBlock %}{% MyCustomTag %}{% MyCustomBlock %}{% MyCustomTag %}{% endMyCustomBlock %}{% endMyCustomBlock %}"

    test_parse(
      tag,
      custom: [
        custom_name: ["MyCustomBlock"],
        custom_markup: "",
        body: [
          custom: [
            {:custom_name, ["MyCustomTag"]},
            {:custom_markup, ""}
          ],
          custom: [
            custom_name: ["MyCustomBlock"],
            custom_markup: "",
            body: [
              custom: [
                {:custom_name, ["MyCustomTag"]},
                {:custom_markup, ""}
              ]
            ]
          ]
        ]
      ]
    )
  end
end
