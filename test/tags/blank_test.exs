Code.require_file("../../test_helper.exs", __ENV__.file)

defmodule Liquid.BlankTest do
  use ExUnit.Case

  setup do
    start_supervised!({Liquid.Process, [name: :liquid]})
    :ok
  end

  def n, do: "10"

  def wrap_in_for(body) do
    "{% for i  in (1.." <> n() <> ") %}" <> body <> "{% endfor %}"
  end

  def wrap_in_if(body) do
    "{% if true %}" <> body <> "{% endif %}"
  end

  def wrap(body) do
    wrap_in_for(body) <> wrap_in_if(body)
  end

  test :test_loops_are_blank do
    assert_result("", wrap_in_for(" "), %{})
  end

  test :test_if_else_are_blank do
    assert_template_result("", "{% if true %} {% elsif false %} {% else %} {% endif %}")
  end

  test :test_unless_is_blank do
    assert_template_result("", wrap("{% unless true %} {% endunless %}"))
  end

  test :test_mark_as_blank_only_during_parsing do
    assert_template_result(
      String.duplicate(" ", String.to_integer(n()) + 1),
      wrap(" {% if false %} this never happens, but still, this block is not blank {% endif %}")
    )
  end

  test :test_comments_are_blank do
    assert_template_result("", wrap(" {% comment %} whatever {% endcomment %} "))
  end

  test :test_captures_are_blank do
    assert_template_result("", wrap(" {% capture foo %} whatever {% endcapture %} "))
  end

  test :test_nested_blocks_are_blank_but_only_if_all_children_are do
    assert_template_result("", wrap(wrap(" ")))

    assert_template_result(
      String.duplicate("\n       but this is not ", String.to_integer(n()) + 1),
      wrap(
        "{% if true %} {% comment %} this is blank {% endcomment %} {% endif %}\n      {% if true %} but this is not {% endif %}"
      )
    )
  end

  test :test_assigns_are_blank do
    assert_template_result("", wrap(" {% assign foo = \"bar\" %} "))
  end

  test :loop_test do
    assert_template_result("testtesttesttesttesttesttesttesttesttesttest", wrap("test"))
  end

  defp assert_template_result(expected, markup) do
    assert_result(expected, markup, %{})
  end

  defp assert_result(expected, markup, assigns) do
    template = Liquid.parse_template(:liquid, markup)
    {:ok, result, _} = Liquid.render_template(:liquid, template, assigns)
    assert result == expected
  end
end
