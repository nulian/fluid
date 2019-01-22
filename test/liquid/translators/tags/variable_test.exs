defmodule Liquid.Translators.Tags.VariableTest do
  use ExUnit.Case
  import Liquid.Helpers

  test "assign translate new AST to old AST" do
    [
      {"{{ 'string' }}", %{}},
      {"{{ variable }}", %{}},
      {"{{ variable.value }}", %{}},
      {"{{ variable.value[0] }}", %{}},
      {"{{ variable.value[index] }}", %{}},
      {"{{ 'string' }} | capitalize ", %{}},
      {"{{ variable | capitalize }}", %{}},
      {"{{ variable.value | capitalize}}", %{}},
      {"{{ variable.value[0] | capitalize}}", %{}},
      {"{{ variable.value[index] | capitalize}}", %{}},
      {"{{ 'string' | capitalize | divided_by: 0}}", %{}},
      {"{{ variable | capitalize | divided_by: 0}}", %{}},
      {"{{ variable.value | capitalize | divided_by: 0}}", %{}},
      {"{{ variable.value[0] | capitalize | divided_by: 0}}", %{}},
      {"{{ variable.value[index] | capitalize | divided_by: 0}}", %{}}
    ]
    |> Enum.each(fn {tag, params} ->
      test_ast_translation(tag, params)
    end)
  end
end
