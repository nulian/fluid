defmodule Liquid.Combinators.Tags.RawTest do
  use ExUnit.Case

  import Liquid.Helpers

  test "raw tag parser" do
    test_parse(
      "{% raw %} Raw temporarily disables tag processing. This is useful for generating content (eg, Mustache, Handlebars )like this {{ product }} which uses conflicting syntax.{% endraw %}",
      raw: [
        " Raw temporarily disables tag processing. This is useful for generating content (eg, Mustache, Handlebars )like this {{ product }} which uses conflicting syntax."
      ]
    )
  end

  test "raw with tags and variables in body" do
    test_parse(
      "{% raw %} {% if true %} {% endraw %}",
      raw: [" {% if true %} "]
    )
  end
end
