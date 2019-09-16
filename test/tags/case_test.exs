Code.require_file("../../test_helper.exs", __ENV__.file)

defmodule Liquid.CaseTest do
  use ExUnit.Case

  test "render first block with a matching {% when %} argument" do
    assert_result(
      " its 1 ",
      "{% case condition %}{% when 1 %} its 1 {% when 2 %} its 2 {% endcase %}",
      %{"condition" => 1}
    )

    assert_result(
      " its 2 ",
      "{% case condition %}{% when 1 %} its 1 {% when 2 %} its 2 {% endcase %}",
      %{"condition" => 2}
    )

    # dont render whitespace between case and first when
    assert_result(
      " its 2 ",
      "{% case condition %} {% when 1 %} its 1 {% when 2 %} its 2 {% endcase %}",
      %{"condition" => 2}
    )
  end

  test "match strings correctly" do
    assert_result(" hit ", "{% case condition %}{% when \"string here\" %} hit {% endcase %}", %{
      "condition" => "string here"
    })

    assert_result("", "{% case condition %}{% when \"string here\" %} hit {% endcase %}", %{
      "condition" => "bad string here"
    })
  end

  test "wont render anything if no matches found" do
    assert_result(
      "  ",
      " {% case condition %}{% when 1 %} its 1 {% when 2 %} its 2 {% endcase %} ",
      %{"condition" => 3}
    )
  end

  test "evaluate variables and expressions" do
    assert_result("", "{% case a.size %}{% when 1 %}1{% when 2 %}2{% endcase %}", %{"a" => []})
    assert_result("1", "{% case a.size %}{% when 1 %}1{% when 2 %}2{% endcase %}", %{"a" => [1]})

    assert_result("2", "{% case a.size %}{% when 1 %}1{% when 2 %}2{% endcase %}", %{
      "a" => [1, 1]
    })

    assert_result("", "{% case a.size %}{% when 1 %}1{% when 2 %}2{% endcase %}", %{
      "a" => [1, 1, 1]
    })

    assert_result("", "{% case a.size %}{% when 1 %}1{% when 2 %}2{% endcase %}", %{
      "a" => [1, 1, 1, 1]
    })

    assert_result("", "{% case a.size %}{% when 1 %}1{% when 2 %}2{% endcase %}", %{
      "a" => [1, 1, 1, 1, 1]
    })
  end

  test "allow assignment from within a {% when %} block" do
    # Example from the shopify forums
    template =
      "{% case collection.handle %}" <>
        "{% when 'menswear-jackets' %}" <>
        "{% assign ptitle = 'menswear' %}" <>
        "{% when 'menswear-t-shirts' %}" <>
        "{% assign ptitle = 'menswear' %}" <>
        "{% else %}" <> "{% assign ptitle = 'womenswear' %}" <> "{% endcase %}" <> "{{ ptitle }}"

    assert_result("menswear", template, %{"collection" => %{"handle" => "menswear-jackets"}})
    assert_result("menswear", template, %{"collection" => %{"handle" => "menswear-t-shirts"}})
    assert_result("womenswear", template, %{"collection" => %{"handle" => "x"}})
    assert_result("womenswear", template, %{"collection" => %{"handle" => "y"}})
    assert_result("womenswear", template, %{"collection" => %{"handle" => "z"}})
  end

  test "allows use of 'or' to chain parameters with {% when %}" do
    template =
      "{% case condition %}" <>
        "{% when 1 or 2 or 3 %} its 1 or 2 or 3 " <> "{% when 4 %} its 4 {% endcase %}"

    assert_result(" its 1 or 2 or 3 ", template, %{"condition" => 1})
    assert_result(" its 1 or 2 or 3 ", template, %{"condition" => 2})
    assert_result(" its 1 or 2 or 3 ", template, %{"condition" => 3})
    assert_result(" its 4 ", template, %{"condition" => 4})
    assert_result("", template, %{"condition" => 5})

    template =
      "{% case condition %}" <>
        "{% when 1 or \"string\" or null %} its 1 or 2 or 3 " <>
        "{% when 4 %} its 4 {% endcase %}"

    assert_result(" its 1 or 2 or 3 ", template, %{"condition" => 1})
    assert_result(" its 1 or 2 or 3 ", template, %{"condition" => "string"})
    assert_result(" its 1 or 2 or 3 ", template, %{"condition" => nil})
    assert_result("", template, %{"condition" => "something else"})
  end

  test "allows use of commas to chain parameters with {% when %} " do
    template =
      "{% case condition %}" <>
        "{% when 1, 2, 3 %} its 1 or 2 or 3 " <> "{% when 4 %} its 4 {% endcase %}"

    assert_result(" its 1 or 2 or 3 ", template, %{"condition" => 1})
    assert_result(" its 1 or 2 or 3 ", template, %{"condition" => 2})
    assert_result(" its 1 or 2 or 3 ", template, %{"condition" => 3})
    assert_result(" its 4 ", template, %{"condition" => 4})
    assert_result("", template, %{"condition" => 5})

    template =
      "{% case condition %}" <>
        "{% when 1, \"string\", null %} its 1 or 2 or 3 " <> "{% when 4 %} its 4 {% endcase %}"

    assert_result(" its 1 or 2 or 3 ", template, %{"condition" => 1})
    assert_result(" its 1 or 2 or 3 ", template, %{"condition" => "string"})
    assert_result(" its 1 or 2 or 3 ", template, %{"condition" => nil})
    assert_result("", template, %{"condition" => "something else"})
  end

  # test "error on bad syntax" do
  #   # assert_raise Liquid.SyntaxError fn ->
  #   {:error, _ } = "{% case false %}{% when %}true{% endcase %}" |> Template.parse
  #                                                                |> Template.render
  #   # end

  #   # expect {
  #   {:error, _} = "{% case false %}{% huh %}true{% endcase %}" |> Template.parse
  #                                                              |> Template.render
  #   # }.to raise_error(Liquid::SyntaxError)
  # end

  test "renders the {% else %} block when no matches found" do
    assert_result(
      " hit ",
      "{% case condition %}{% when 5 %} hit {% else %} else {% endcase %}",
      %{"condition" => 5}
    )

    assert_result(
      " else ",
      "{% case condition %}{% when 5 %} hit {% else %} else {% endcase %}",
      %{"condition" => 6}
    )
  end

  test "should evaluate variables and expressions" do
    assert_result(
      "else",
      "{% case a.size %}{% when 1 %}1{% when 2 %}2{% else %}else{% endcase %}",
      %{"a" => []}
    )

    assert_result(
      "1",
      "{% case a.size %}{% when 1 %}1{% when 2 %}2{% else %}else{% endcase %}",
      %{"a" => [1]}
    )

    assert_result(
      "2",
      "{% case a.size %}{% when 1 %}1{% when 2 %}2{% else %}else{% endcase %}",
      %{"a" => [1, 1]}
    )

    assert_result(
      "else",
      "{% case a.size %}{% when 1 %}1{% when 2 %}2{% else %}else{% endcase %}",
      %{"a" => [1, 1, 1]}
    )

    assert_result(
      "else",
      "{% case a.size %}{% when 1 %}1{% when 2 %}2{% else %}else{% endcase %}",
      %{"a" => [1, 1, 1, 1]}
    )

    assert_result(
      "else",
      "{% case a.size %}{% when 1 %}1{% when 2 %}2{% else %}else{% endcase %}",
      %{"a" => [1, 1, 1, 1, 1]}
    )

    assert_result(
      "else",
      "{% case a.empty? %}{% when true %}true{% when false %}false{% else %}else{% endcase %}",
      %{}
    )

    assert_result(
      "false",
      "{% case false %}{% when true %}true{% when false %}false{% else %}else{% endcase %}",
      %{}
    )

    assert_result(
      "true",
      "{% case true %}{% when true %}true{% when false %}false{% else %}else{% endcase %}",
      %{}
    )

    assert_result(
      "else",
      "{% case NULL %}{% when true %}true{% when false %}false{% else %}else{% endcase %}"
    )
  end

  defp assert_result(expected, markup), do: assert_result(expected, markup, %Liquid.Context{})

  defp assert_result(expected, markup, %Liquid.Context{} = context) do
    t = Liquid.Template.parse(markup)
    {:ok, rendered, _context} = Liquid.Template.render(t, context)
    assert expected == rendered
  end

  defp assert_result(expected, markup, assigns) do
    context = %Liquid.Context{assigns: assigns}
    assert_result(expected, markup, context)
  end
end
