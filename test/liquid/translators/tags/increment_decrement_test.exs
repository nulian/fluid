defmodule Liquid.Translators.Tags.IncrementDecrementTest do
  use ExUnit.Case
  import Liquid.Helpers

  test "increment / decrement translate new AST to old AST" do
    params = %{"port" => 1, "startboard" => 2}

    [
      "{%increment port %}",
      "{%increment port %} {%increment port%}",
      "{%increment port %} {%increment starboard%} {%increment port %} {%increment port%} {%increment starboard %}",
      "{%decrement port %}",
      "{%decrement port %} {%decrement port%}",
      "{%increment port %} {%increment starboard%} {%increment port %} {%decrement port%} {%decrement starboard %}"
    ]
    |> Enum.each(fn tag ->
      test_ast_translation(tag, params)
    end)
  end
end
