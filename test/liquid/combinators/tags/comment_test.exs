defmodule Liquid.Combinator.Tags.CommentTest do
  use ExUnit.Case

  import Liquid.Helpers
  alias Liquid.NimbleParser, as: Parser

  test "comment tag parser" do
    test_combinator(
      "{% comment %} Allows you to leave un-rendered code inside a Liquid template. Any text within the opening and closing comment blocks will not be output, and any Liquid code within will not be executed. {% endcomment %}",
      &Parser.comment/1,
      {:ok, [literal: [""]], "", %{}, {1, 0}, 217}
    )
  end
end
