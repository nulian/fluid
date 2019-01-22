defmodule Liquid.Translators.Tags.AssignTest do
  use ExUnit.Case
  import Liquid.Helpers

  test "assign translate new AST to old AST" do
    [
      {"{% assign a = 5 %}{{ a }}", %{}},
      {"{% assign foo = values %}.{{ foo[0] }}.", %{"values" => ["foo", "bar", "baz"]}},
      {"{% assign foo = values %}.{{ foo[1] }}.", %{"values" => ["foo", "bar", "baz"]}},
      {"{% assign foo = values | split: ',' %}.{{ foo[1] }}.", %{"values" => "foo,bar,baz"}}
    ]
    |> Enum.each(fn {tag, params} ->
      test_ast_translation(tag, params)
    end)
  end
end
