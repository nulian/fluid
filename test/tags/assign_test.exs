defmodule Liquid.AssignTest do
  use ExUnit.Case

  setup_all do
    Liquid.start()
    on_exit(fn -> Liquid.stop() end)
    :ok
  end

  test :assigned_variable do
    assert_result(".foo.", "{% assign foo = values %}.{{ foo[0] }}.", %{
      "values" => ["foo", "bar", "baz"]
    })

    assert_result(".bar.", "{% assign foo = values %}.{{ foo[1] }}.", %{
      "values" => ["foo", "bar", "baz"]
    })
  end

  test :assign_with_filter do
    assert_result(".Foo.", "{% assign foo = values | capitalize | split: ',' %}.{{ foo[0] }}.", %{
      "values" => "foo,bar,baz"
    })
  end

  test "assign string to var and then show" do
    assert_result("test", "{% assign foo = 'test' %}{{foo}}", %{})
  end

  defp assert_result(expected, markup, assigns) do
    template = Liquid.Template.parse(markup)
    {:ok, result, _} = Liquid.Template.render(template, assigns)
    assert result == expected
  end
end
