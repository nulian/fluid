defmodule Liquid.Combinators.Tags.CaptureTest do
  use ExUnit.Case

  import Liquid.Helpers
  alias Liquid.NimbleParser, as: Parser

  test "capture tag: parser basic structures" do
    test_combinator(
      "{% capture about_me %} I am {{ age }} and my favorite food is {{ favorite_food }}. {% endcapture %}",
      &Parser.capture/1,
      [
        {:capture,
          [
            variable_name: "about_me",
            capture_sentences: [
              " I am ",
              {:variable, [variable_name: "age"]},
              " and my favorite food is ",
              {:variable, [variable_name: "favorite_food"]},
              ". "
            ]
          ]},
        ""
      ]
    )
  end
end
