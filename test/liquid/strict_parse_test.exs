defmodule TestFileSystemStrict do
  def read_template_file(_root, template_path, _context) do
    case template_path do
      "bad_template" ->
        {:ok, "{% for a in b %} ..."}

      "bad_division" ->
        {:ok, "{{ 16  | divided_by: 0 }}"}

      _ ->
        {:ok, template_path}
    end
  end
end

defmodule Liquid.StrictParseTest do
  use ExUnit.Case

  alias Liquid.{Template, SyntaxError}

  setup_all do
    Liquid.FileSystem.register(TestFileSystemStrict)
    :ok
  end

  test "error on empty filter" do
    assert_syntax_error("{{|test}}")
    assert_syntax_error("{{test |a|b|}}")
  end

  test "meaningless parens error" do
    markup = "a == 'foo' or (b == 'bar' and c == 'baz') or false"
    assert_syntax_error("{% if #{markup} %} YES {% endif %}")
  end

  test "unexpected characters syntax error" do
    markup = "true ^& false"
    assert_syntax_error("{% if #{markup} %} YES {% endif %}")
  end

  test "incomplete close variable" do
    assert_syntax_error("TEST {{method}")
  end

  test "incomplete close tag" do
    assert_syntax_error("TEST {% tag }")
  end

  test "open tag without close" do
    assert_syntax_error("TEST {%")
  end

  test "open variable without close" do
    assert_syntax_error("TEST {{")
  end

  test "syntax error" do
    template = "{{ 16  | divided_by: 0 }}"

    assert "variable: 16, Liquid error: divided by 0, filename: root" ==
             template |> Template.parse() |> Template.render() |> elem(1)
  end

  test "missing endtag parse time error" do
    assert_raise RuntimeError, "No matching end for block {% for %} in file: root", fn ->
      Template.parse("{% for a in b %} ...")
    end
  end

  test "missing endtag parse time error within included file" do
    assert_raise RuntimeError, "No matching end for block {% for %} in file: bad_template", fn ->
      "{% include 'bad_template' %}"
      |> Template.parse()
      |> Template.render()
    end
  end

  test "bad filter in included file" do
    template = "{% include 'bad_division' %}"

    assert "variable: 16, Liquid error: divided by 0, filename: bad_division" ==
             template |> Template.parse() |> Template.render() |> elem(1)
  end

  test "unrecognized operator" do
    assert_raise SyntaxError, "Unexpected character in '1 =! 2'", fn ->
      Template.parse("{% if 1 =! 2 %}ok{% endif %}")
    end

    assert_raise SyntaxError, "Invalid variable name", fn -> Template.parse("{{%%%}}") end
  end

  defp assert_syntax_error(markup) do
    assert_raise(SyntaxError, fn -> Template.parse(markup) end)
  end
end
