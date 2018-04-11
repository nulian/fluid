defmodule Liquid.Filters.MathTest do
  use ExUnit.Case
  use Timex
  doctest Liquid.Filters.Math

  alias Liquid.{Filters, Template, Variable}
  alias Liquid.Filters.{Additionals, HTML, List, Math, String}

  setup_all do
    Liquid.start()
    on_exit(fn -> Liquid.stop() end)
    :ok
  end

  test :plus do
    assert_template_result("2", "{{ 1 | plus:1 }}")
    assert_template_result("2.0", "{{ '1' | plus:'1.0' }}")
  end

  test :minus do
    assert_template_result("4", "{{ input | minus:operand }}", %{"input" => 5, "operand" => 1})
    assert_template_result("2.3", "{{ '4.3' | minus:'2' }}")
  end

  test :times do
    assert_template_result("12", "{{ 3 | times:4 }}")
    assert_template_result("0", "{{ 'foo' | times:4 }}")

    assert_template_result("6", "{{ '2.1' | times:3 | replace: '.','-' | plus:0}}")

    assert_template_result("7.25", "{{ 0.0725 | times:100 }}")
  end

  test :divided_by do
    assert_template_result("4", "{{ 12 | divided_by:3 }}")
    assert_template_result("4", "{{ 14 | divided_by:3 }}")
    assert_template_result("5", "{{ 15 | divided_by:3 }}")

    assert_template_result("Liquid error: divided by 0", "{{ 5 | divided_by:0 }}")

    assert_template_result("0.5", "{{ 2.0 | divided_by:4 }}")
  end

  test :abs do
    assert_template_result("3", "{{ '3' | abs }}")
    assert_template_result("3", "{{ -3 | abs }}")
    assert_template_result("0", "{{ 0 | abs }}")
    assert_template_result("0.1", "{{ -0.1 | abs }}")
  end

  test :modulo do
    assert_template_result("1", "{{ 3 | modulo:2 }}")
    assert_template_result("24", "{{ -1 | modulo:25 }}")
  end

  test :round do
    assert_template_result("4", "{{ '4.3' | round }}")
    assert_template_result("5", "{{ input | round }}", %{"input" => 4.6})
    assert_template_result("4.56", "{{ input | round: 2 }}", %{"input" => 4.5612})
  end

  test :ceil do
    assert_template_result("5", "{{ '4.3' | ceil }}")
    assert_template_result("5", "{{ input | ceil }}", %{"input" => 4.6})
  end

  test :floor do
    assert_template_result("4", "{{ '4.3' | floor }}")
    assert_template_result("4", "{{ input | floor }}", %{"input" => 4.6})
  end

  #Helper Test Builder Functions
  defp assert_template_result(expected, markup, assigns \\ %{})

  defp assert_template_result(expected, markup, assigns) do
    assert_result(expected, markup, assigns)
  end

  defp assert_result(expected, markup, assigns) do
    template = Template.parse(markup)

    with {:ok, result, _} <- Template.render(template, assigns) do
      assert result == expected
    else
      {:error, message, _} ->
        assert message == expected
    end
  end

end