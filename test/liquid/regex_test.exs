defmodule Liquid.RegexTest do
  use ExUnit.Case

  test :empty do
    assert_quoted_fragment([], "")
  end

  test :quote do
    assert_quoted_fragment(["\"arg 1\""], "\"arg 1\"")
  end

  test :words do
    assert_quoted_fragment(["arg1", "arg2"], "arg1 arg2")
  end

  test :tags do
    assert_quoted_fragment(["<tr>", "</tr>"], "<tr> </tr>")
    assert_quoted_fragment(["<tr></tr>"], "<tr></tr>")

    assert_quoted_fragment(
      ["<style", "class=\"hello\">", "</style>"],
      "<style class=\"hello\">' </style>"
    )
  end

  test :quoted_words do
    assert_quoted_fragment(["arg1", "arg2", "\"arg 3\""], "arg1 arg2 \"arg 3\"")
    assert_quoted_fragment(["arg1", "arg2", "'arg 3'"], "arg1 arg2 \'arg 3\'")
  end

  test :quoted_words_in_the_middle do
    assert_quoted_fragment(["arg1", "arg2", "\"arg 3\"", "arg4"], "arg1 arg2 \"arg 3\" arg4   ")
  end

  test :variable_parser do
    assert_variable(["var"], "var")
    assert_variable(["var", "method"], "var.method")
    assert_variable(["var", "[method]"], "var[method]")
    assert_variable(["var", "[method]", "[0]"], "var[method][0]")
    assert_variable(["var", "[\"method\"]", "[0]"], "var[\"method\"][0]")
    assert_variable(["var", "[method]", "[0]", "method"], "var[method][0].method")
  end

  def assert_quoted_fragment(expected, markup) do
    tokens = ~r/#{Liquid.quoted_fragment()}/ |> Regex.scan(markup) |> List.flatten()
    assert expected == tokens
  end

  def assert_variable(expected, markup) do
    tokens = Liquid.variable_parser() |> Regex.scan(markup) |> List.flatten()
    assert expected == tokens
  end
end
