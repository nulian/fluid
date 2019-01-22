defmodule Liquid.Combinators.Tags.IfchangedTest do
  use ExUnit.Case

  import Liquid.Helpers

  test "ifchanged tag: basic tag structures" do
    tags = [
      "{% ifchanged %}<h3>{{ product.created_at | date:\"%w\" }}</h3>{% endifchanged %}",
      "{%ifchanged%}<h3>{{ product.created_at | date:\"%w\" }}</h3>{%endifchanged%}",
      "{%      ifchanged         %}<h3>{{ product.created_at | date:\"%w\" }}</h3>{%      endifchanged      %}"
    ]

    Enum.each(tags, fn tag ->
      test_parse(
        tag,
        ifchanged: [
          body: [
            "<h3>",
            {:liquid_variable,
             [
               variable: [
                 parts: [part: "product", part: "created_at"],
                 filters: [filter: ["date", {:params, [value: "%w"]}]]
               ]
             ]},
            "</h3>"
          ]
        ]
      )
    end)
  end
end
