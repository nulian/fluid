defmodule Liquid.Translators.Tags.IfTest do
  use ExUnit.Case
  import Liquid.Helpers

  test "if translate new AST to old AST, without params" do
    [
      "{% if true == empty %}?{% endif %}",
      "{% if true == null %}?{% endif %}",
      "{% if empty == true %}?{% endif %}",
      "{% if null == true %}?{% endif %}",
      "{% if false %} this text should not go into the output {% endif %}",
      "{% if true %} this text should go into the output {% endif %}",
      "{% if false %} you suck {% endif %} {% if true %} you rock {% endif %}?",
      "{% if false %} NO {% else %} YES {% endif %}",
      "{% if true %} YES {% else %} NO {% endif %}",
      "{% if \"foo\" %} YES {% else %} NO {% endif %}",
      "{% if true %} YES\n\r\n {% else %} NO\n\r\n {% endif %}"
    ]
    |> Enum.each(fn tag ->
      test_ast_translation(tag)
    end)
  end

  test "if translate new AST to old AST, with params" do
    [
      {"{% if var %} YES {% endif %}", %{"var" => true}},
      {"{% if a or b %} YES {% endif %}", %{"a" => true, "b" => true}},
      {"{% if a or b %} YES {% endif %}", %{"a" => true, "b" => false}},
      {"{% if a or b %} YES {% endif %}", %{"a" => false, "b" => true}},
      {"{% if a or b %} YES {% endif %}", %{"a" => false, "b" => false}},
      {"{% if a or b or c%} YES {% endif %}", %{"a" => false, "b" => false, "c" => true}},
      {"{% if a or b or c%} YES {% endif %}", %{"a" => false, "b" => false, "c" => false}}
    ]
    |> Enum.each(fn {tag, params} ->
      test_ast_translation(tag, params)
    end)
  end
end
