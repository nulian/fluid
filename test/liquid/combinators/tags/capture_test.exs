defmodule Liquid.Combinators.Tags.CaptureTest do
  use ExUnit.Case

  import Liquid.Helpers
  alias Liquid.NimbleParser, as: Parser

  test "capture tag: parser basic structures" do
    test_combinator(
      "{% capture about_me %} I am {{ age }} and my favorite food is {{ favorite_food }}{% endcapture %}",
      &Parser.capture/1,
      capture: [
        variable_name: "about_me",
        capture_sentences: [
          " I am ",
          {:variable, ["age"]},
          " and my favorite food is ",
          {:variable, ["favorite_food"]}
        ]
      ]
    )
  end

  test "fails in capture tag" do
    [
      "{% capture about_me %} I am {{ age } and my favorite food is { favorite_food }} {% endcapture %}",
      "{% capture about_me %}{% ndcapture %}"
    ]
    |> Enum.each(fn bad_markup -> test_combinator_error(bad_markup, &Parser.capture/1) end)
  end
end
