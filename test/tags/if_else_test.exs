defmodule Liquid.Tags.IfElseTagTest do
  use ExUnit.Case

  alias Liquid.Template, as: Template

  setup_all do
    Liquid.start()
    on_exit(fn -> Liquid.stop() end)
    :ok
  end

  test :if_block do
    assert_result("  ", " {% if false %} this text should not go into the output {% endif %} ")

    assert_result(
      "  this text should go into the output  ",
      " {% if true %} this text should go into the output {% endif %} "
    )

    assert_result(
      "  you rock ?",
      "{% if false %} you suck {% endif %} {% if true %} you rock {% endif %}?"
    )
  end

  test :if_else do
    assert_result(" YES ", "{% if false %} NO {% else %} YES {% endif %}")
    assert_result(" YES ", "{% if true %} YES {% else %} NO {% endif %}")
    assert_result(" YES ", "{% if \"foo\" %} YES {% else %} NO {% endif %}")
  end

  test :if_boolean do
    assert_result(" YES ", "{% if var %} YES {% endif %}", %{"var" => true})
  end

  test :if_or do
    assert_result(" YES ", "{% if a or b %} YES {% endif %}", %{"a" => true, "b" => true})
    assert_result(" YES ", "{% if a or b %} YES {% endif %}", %{"a" => true, "b" => false})
    assert_result(" YES ", "{% if a or b %} YES {% endif %}", %{"a" => false, "b" => true})
    assert_result("", "{% if a or b %} YES {% endif %}", %{"a" => false, "b" => false})

    assert_result(" YES ", "{% if a or b or c %} YES {% endif %}", %{
      "a" => false,
      "b" => false,
      "c" => true
    })

    assert_result("", "{% if a or b or c %} YES {% endif %}", %{
      "a" => false,
      "b" => false,
      "c" => false
    })
  end

  test :if_or_with_operators do
    assert_result(" YES ", "{% if a == true or b == true %} YES {% endif %}", %{
      "a" => true,
      "b" => true
    })

    assert_result(" YES ", "{% if a == true or b == false %} YES {% endif %}", %{
      "a" => true,
      "b" => true
    })

    assert_result("", "{% if a == false or b == false %} YES {% endif %}", %{
      "a" => true,
      "b" => true
    })

    assert_result(
      " YES ",
      "{% if a == false and b == false and c == false  %} YES {% endif %}",
      %{
        "a" => false,
        "b" => false,
        "c" => false
      }
    )

    template_body = """
      {% if v1 == 1 and v2 == 2 and v3 == 3 %} Hello {% endif %}
    """

    assert_result("  \n", template_body, %{"v1" => 2, "v2" => 2, "v3" => 3})
    assert_result("   Hello \n", template_body, %{"v1" => 1, "v2" => 2, "v3" => 3})
  end

  test :comparison_of_strings_containing_and_or_or do
    awful_markup =
      "a == 'and' and b == 'or' and c == 'foo and bar' and d == 'bar or baz' and e == 'foo' and foo and bar"

    assigns = %{
      "a" => "and",
      "b" => "or",
      "c" => "foo and bar",
      "d" => "bar or baz",
      "e" => "foo",
      "foo" => true,
      "bar" => true
    }

    assert_result(" YES ", "{% if #{awful_markup} %} YES {% endif %}", assigns)
  end

  test :comparison_of_expressions_starting_with_and_or_or do
    assigns = %{"order" => %{"items_count" => 0}, "android" => %{"name" => "Roy"}}

    assert_result("YES", "{% if android.name == 'Roy' %}YES{% endif %}", assigns)
    assert_result("YES", "{% if order.items_count == 0 %}YES{% endif %}", assigns)
  end

  test :if_and do
    assert_result(" YES ", "{% if true and true %} YES {% endif %}")
    assert_result("", "{% if false and true %} YES {% endif %}")
    assert_result("", "{% if false and true %} YES {% endif %}")
  end

  test :hash_miss_generates_false do
    assert_result("", "{% if foo.bar %} NO {% endif %}", %{"foo" => %{}})
  end

  test :if_from_variable do
    assert_result("", "{% if var %} NO {% endif %}", %{"var" => false})
    assert_result("", "{% if var %} NO {% endif %}", %{"var" => nil})
    assert_result("", "{% if foo.bar %} NO {% endif %}", %{"foo" => %{"bar" => false}})
    assert_result("", "{% if foo.bar %} NO {% endif %}", %{"foo" => %{}})

    assert_result("", "{% if foo.bar %} NO {% endif %}", %{"foo" => nil})

    assert_result("", "{% if foo.bar %} NO {% endif %}", %{"foo" => true})

    assert_result(" YES ", "{% if var %} YES {% endif %}", %{"var" => "text"})
    assert_result(" YES ", "{% if var %} YES {% endif %}", %{"var" => true})
    assert_result(" YES ", "{% if var %} YES {% endif %}", %{"var" => 1})
    assert_result(" YES ", "{% if var %} YES {% endif %}", %{"var" => %{}})
    assert_result(" YES ", "{% if var %} YES {% endif %}", %{"var" => %{}})
    assert_result(" YES ", "{% if \"foo\" %} YES {% endif %}")
    assert_result(" YES ", "{% if foo.bar %} YES {% endif %}", %{"foo" => %{"bar" => true}})
    assert_result(" YES ", "{% if foo.bar %} YES {% endif %}", %{"foo" => %{"bar" => "text"}})
    assert_result(" YES ", "{% if foo.bar %} YES {% endif %}", %{"foo" => %{"bar" => 1}})
    assert_result(" YES ", "{% if foo.bar %} YES {% endif %}", %{"foo" => %{"bar" => %{}}})
    assert_result(" YES ", "{% if foo.bar %} YES {% endif %}", %{"foo" => %{"bar" => %{}}})

    assert_result(" YES ", "{% if var %} NO {% else %} YES {% endif %}", %{"var" => false})
    assert_result(" YES ", "{% if var %} NO {% else %} YES {% endif %}", %{"var" => nil})
    assert_result(" YES ", "{% if var %} YES {% else %} NO {% endif %}", %{"var" => true})
    assert_result(" YES ", "{% if \"foo\" %} YES {% else %} NO {% endif %}", %{"var" => "text"})

    assert_result(" YES ", "{% if foo.bar %} NO {% else %} YES {% endif %}", %{
      "foo" => %{"bar" => false}
    })

    assert_result(" YES ", "{% if foo.bar %} YES {% else %} NO {% endif %}", %{
      "foo" => %{"bar" => true}
    })

    assert_result(" YES ", "{% if foo.bar %} YES {% else %} NO {% endif %}", %{
      "foo" => %{"bar" => "text"}
    })

    assert_result(" YES ", "{% if foo.bar %} NO {% else %} YES {% endif %}", %{
      "foo" => %{"notbar" => true}
    })

    assert_result(" YES ", "{% if foo.bar %} NO {% else %} YES {% endif %}", %{"foo" => %{}})

    assert_result(" YES ", "{% if foo.bar %} NO {% else %} YES {% endif %}", %{
      "notfoo" => %{"bar" => true}
    })
  end

  test :nested_if do
    assert_result("", "{% if false %}{% if false %} NO {% endif %}{% endif %}")
    assert_result("", "{% if false %}{% if true %} NO {% endif %}{% endif %}")
    assert_result("", "{% if true %}{% if false %} NO {% endif %}{% endif %}")
    assert_result(" YES ", "{% if true %}{% if true %} YES {% endif %}{% endif %}")

    assert_result(
      " YES ",
      "{% if true %}{% if true %} YES {% else %} NO {% endif %}{% else %} NO {% endif %}"
    )

    assert_result(
      " YES ",
      "{% if true %}{% if false %} NO {% else %} YES {% endif %}{% else %} NO {% endif %}"
    )

    assert_result(
      " YES ",
      "{% if false %}{% if true %} NO {% else %} NONO {% endif %}{% else %} YES {% endif %}"
    )
  end

  test :comparisons_on_null do
    assert_result("", "{% if null < 10 %} NO {% endif %}")
    assert_result("", "{% if null <= 10 %} NO {% endif %}")
    assert_result("", "{% if null >= 10 %} NO {% endif %}")
    assert_result("", "{% if null > 10 %} NO {% endif %}")

    assert_result("", "{% if 10 < null %} NO {% endif %}")
    assert_result("", "{% if 10 <= null %} NO {% endif %}")
    assert_result("", "{% if 10 >= null %} NO {% endif %}")
    assert_result("", "{% if 10 > null %} NO {% endif %}")
  end

  test :else_if do
    assert_result("0", "{% if 0 == 0 %}0{% elsif 1 == 1%}1{% else %}2{% endif %}")
    assert_result("1", "{% if 0 != 0 %}0{% elsif 1 == 1%}1{% else %}2{% endif %}")
    assert_result("2", "{% if 0 != 0 %}0{% elsif 1 != 1%}1{% else %}2{% endif %}")

    assert_result("elsif", "{% if false %}if{% elsif true %}elsif{% endif %}")
  end

  # test :syntax_error_no_variable do
  #   assert_raise(SyntaxError){ assert_result("", "{% if jerry == 1 %}")}
  # end

  # test :syntax_error_no_expression do
  #   assert_raise Liquid.SyntaxError, fn ->
  #     assert_result("", "{% if %}")
  #   end
  # end

  test :if_with_contains_condition do
    assert_result("yes", "{% if 'bob' contains 'o' %}yes{% endif %}")
    assert_result("no", "{% if 'bob' contains 'f' %}yes{% else %}no{% endif %}")

    assert_result(
      "yes",
      "{% if 'gnomeslab-and-or-liquid' contains 'gnomeslab-and-or-liquid' %}yes{% endif %}"
    )
  end

  defp assert_result(expected, markup, assigns \\ %{}) do
    t = Template.parse(markup)
    {:ok, rendered, _} = Template.render(t, assigns)
    assert rendered == expected

    ast =
      quote do
        cond do
          1 == 1 or 3 == 3 -> 55
          2 == 2 -> 2
          true -> 3
        end
      end

    Code.eval_quoted(ast)
  end
end
