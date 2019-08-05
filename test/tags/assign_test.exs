Code.require_file("../../test_helper.exs", __ENV__.file)

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
    assert_result(".bar.", "{% assign foo = values | split: ',' %}.{{ foo[1] }}.", %{
      "values" => "foo,bar,baz"
    })
  end

  test "assign string to var and then show" do
    assert_result("test", "{% assign foo = 'test' %}{{foo}}", %{})
  end

  defmodule TestMod do
    @fields [:position]
    defstruct @fields
  end

  test "assign with sort, but elements are structs" do
    assert_result(
      "\n  \n    9\n  \n    10\n  \n",
      """
      {% assign sorted_elements = elements | sort: 'position' %}
        {% for element in sorted_elements %}
          {{ element.position }}
        {% endfor %}
      """,
      %{
        "elements" => [
          %TestMod{
            position: 10
          },
          %TestMod{
            position: 9
          }
        ]
      }
    )
  end

  test "assign with sort, but single element is a struct" do
    assert_result(
      "\n  \n    10\n  \n",
      """
      {% assign sorted_elements = elements | sort: 'position' %}
        {% for element in sorted_elements %}
          {{ element.position }}
        {% endfor %}
      """,
      %{
        "elements" => [
          %TestMod{
            position: 10
          }
        ]
      }
    )
  end

  defp assert_result(expected, markup, assigns) do
    template = Liquid.Template.parse(markup)
    {:ok, result, _} = Liquid.Template.render(template, assigns)
    assert result == expected
  end
end
