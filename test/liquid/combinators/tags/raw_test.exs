defmodule Liquid.Combinator.Tags.RawTest do
  use ExUnit.Case

  import Liquid.Helpers
  alias Liquid.NimbleParser, as: Parser

  test "raw tag parser" do
    test_combinator(
      "{% raw %} Raw temporarily disables tag processing. This is useful for generating content (eg, Mustache, Handlebars )like this {{ product }} which uses conflicting syntax.{% endraw %}",
      &Parser.raw/1,
      [
        {:raw,
         [
           raw_content: [
             " Raw temporarily disables tag processing. This is useful for generating content (eg, Mustache, Handlebars )like this {{ product }} which uses conflicting syntax."
           ]
         ]},
        ""
      ]
    )
  end
end
