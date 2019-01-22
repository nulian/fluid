defmodule Liquid.Translators.Tags.CycleTest do
  use ExUnit.Case
  import Liquid.Helpers

  test "cycle translate new AST to old AST" do
    [
      "{%cycle \"one\", \"two\"%}",
      "{%cycle \"one\", \"two\"%} {%cycle \"one\", \"two\"%}",
      "{%cycle \"\", \"two\"%} {%cycle \"\", \"two\"%}",
      "{%cycle \"one\", \"two\"%} {%cycle \"one\", \"two\"%} {%cycle \"one\", \"two\"%}",
      "{%cycle \"text-align: left\", \"text-align: right\" %} {%cycle \"text-align: left\", \"text-align: right\"%}",
      "{%cycle 1,2%} {%cycle 1,2%} {%cycle 1,2%} {%cycle 1,2,3%} {%cycle 1,2,3%} {%cycle 1,2,3%} {%cycle 1,2,3%}"
    ]
    |> Enum.each(fn tag ->
      test_ast_translation(tag)
    end)

    params = %{"var1" => 1, "var2" => 2}

    tag = """
      {%cycle 1: \"one\", \"two\" %} {%cycle 2: \"one\", \"two\" %}
      {%cycle 1: \"one\", \"two\" %} {%cycle 2: \"one\", \"two\" %}
      {%cycle 1: \"one\", \"two\" %} {%cycle 2: \"one\", \"two\" %}
    """

    test_ast_translation(tag, params)
  end
end
