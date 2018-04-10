defmodule Liquid.StatementsTest do
  use ExUnit.Case
  alias Liquid.Template

  setup_all do
    Liquid.start()
    :ok
  end

  test :test_true_eql_true do
    text = " {% if true == true %} true {% else %} false {% endif %} "
    assert_template_result("  true  ", text)
  end

  test :test_true_not_eql_true do
    text = " {% if true != true %} true {% else %} false {% endif %} "
    assert_template_result("  false  ", text)
  end

  test :test_true_lq_true do
    text = " {% if 0 > 0 %} true {% else %} false {% endif %} "
    assert_template_result("  false  ", text)
  end

  test :test_one_lq_zero do
    text = " {% if 1 > 0 %} true {% else %} false {% endif %} "
    assert_template_result("  true  ", text)
  end

  test :test_zero_lq_one do
    text = " {% if 0 < 1 %} true {% else %} false {% endif %} "
    assert_template_result("  true  ", text)
  end

  test :test_zero_lq_or_equal_one do
    text = " {% if 0 <= 0 %} true {% else %} false {% endif %} "
    assert_template_result("  true  ", text)
  end

  test :test_zero_lq_or_equal_one_involving_nil do
    text = " {% if null <= 0 %} true {% else %} false {% endif %} "
    assert_template_result("  false  ", text)

    text = " {% if 0 <= null %} true {% else %} false {% endif %} "
    assert_template_result("  false  ", text)
  end

  test :test_zero_lqq_or_equal_one do
    text = " {% if 0 >= 0 %} true {% else %} false {% endif %} "
    assert_template_result("  true  ", text)
  end

  test :test_strings do
    text = " {% if 'test' == 'test' %} true {% else %} false {% endif %} "
    assert_template_result("  true  ", text)
  end

  test :test_strings_not_equal do
    text = " {% if 'test' != 'test' %} true {% else %} false {% endif %} "
    assert_template_result("  false  ", text)
  end

  test :test_var_strings_equal do
    text = " {% if var == \"hello there!\" %} true {% else %} false {% endif %} "
    assert_template_result("  true  ", text, %{"var" => "hello there!"})
  end

  test :test_var_strings_are_not_equal do
    text = " {% if \"hello there!\" == var %} true {% else %} false {% endif %} "
    assert_template_result("  true  ", text, %{"var" => "hello there!"})
  end

  test :test_var_and_long_string_are_equal do
    text = " {% if var == 'hello there!' %} true {% else %} false {% endif %} "
    assert_template_result("  true  ", text, %{"var" => "hello there!"})
  end

  test :test_var_and_long_string_are_equal_backwards do
    text = " {% if 'hello there!' == var %} true {% else %} false {% endif %} "
    assert_template_result("  true  ", text, %{"var" => "hello there!"})
  end

  test :test_is_collection_empty do
    text = " {% if array == empty %} true {% else %} false {% endif %} "
    assert_template_result("  true  ", text, %{"array" => []})
  end

  test :test_is_not_collection_empty do
    text = " {% if array == empty %} true {% else %} false {% endif %} "
    assert_template_result("  false  ", text, %{"array" => [1, 2, 3]})
  end

  test :test_nil do
    text = " {% if var == nil %} true {% else %} false {% endif %} "
    assert_template_result("  true  ", text, %{"var" => nil})

    text = " {% if var == null %} true {% else %} false {% endif %} "
    assert_template_result("  true  ", text, %{"var" => nil})
  end

  test :test_not_nil do
    text = " {% if var != nil %} true {% else %} false {% endif %} "
    assert_template_result("  true  ", text, %{"var" => 1})

    text = " {% if var != null %} true {% else %} false {% endif %} "
    assert_template_result("  true  ", text, %{"var" => 1})
  end

  defp assert_template_result(expected, markup) do
    assert_result(expected, markup, %{})
  end

  defp assert_template_result(expected, markup, assigns) do
    assert_result(expected, markup, assigns)
  end

  defp assert_result(expected, markup, assigns) do
    template = Template.parse(markup)
    {:ok, result, _} = Template.render(template, assigns)
    assert result == expected
  end
end
