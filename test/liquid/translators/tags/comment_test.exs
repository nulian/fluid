defmodule Liquid.Translators.Tags.CommentTest do
  use ExUnit.Case

  import Liquid.Helpers

  test "capture translate new AST to old AST" do
    [
      "{% comment %} whatever, no matter {% endcomment %}",
      "{% comment %} {% if true %} {% endcomment %}"
    ]
    |> Enum.each(fn tag ->
      test_ast_translation(tag)
    end)
  end
end
