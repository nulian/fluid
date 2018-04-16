Code.require_file("../../test_helper.exs", __ENV__.file)

defmodule StandardTagTest do
  use ExUnit.Case

  alias Liquid.Template

  setup_all do
    Liquid.start()
    :ok
  end

  test :test_no_transform do
    assert_template_result(
      "this text should come out of the template without change...",
      "this text should come out of the template without change..."
    )

    assert_template_result("blah", "blah")
    assert_template_result("<blah>", "<blah>")
    assert_template_result("|,.:", "|,.:")
    assert_template_result(" ", " ")
    assert_template_result("", "")

    text = """
    this shouldnt see any transformation either but has multiple lines
              as you can clearly see here ...
    """

    assert_template_result(text, text)
  end

  test "comments trick" do
    assert_template_result(
      "11",
      "1{% comment %}{% encomment %}1{%endcomment%}1{% comment %}comment{% endcomment %}"
    )
  end

  test :test_has_a_block_which_does_nothing do
    assert_template_result(
      "the comment block should be removed  .. right?",
      "the comment block should be removed {%comment%} be gone.. {%endcomment%} .. right?"
    )

    assert_template_result("", "{%comment%}{%endcomment%}")
    assert_template_result("", "{%comment%}{% endcomment %}")
    assert_template_result("", "{% comment %}{%endcomment%}")
    assert_template_result("", "{% comment %}{% endcomment %}")
    assert_template_result("", "{%comment%}comment{%endcomment%}")
    assert_template_result("", "{% comment %}comment{% endcomment %}")

    assert_template_result(
      "11",
      "1{% comment %}{ encomment %}1{%endcomment%}1{% comment %}comment{% endcomment %}"
    )

    assert_template_result(
      "1",
      "{% comment %} 1 {% comment %} 2 {% endcomment %} 3 {% endcomment %}1"
    )

    assert_template_result("", "{%comment%}{%blabla%}{%endcomment%}")
    assert_template_result("", "{% comment %}{% blabla %}{% endcomment %}")
    assert_template_result("", "{%comment%}{% endif %}{%endcomment%}")
    assert_template_result("", "{% comment %}{% endwhatever %}{% endcomment %}")

    assert_template_result(
      "",
      "{% comment %}{% raw %} {{%%%%}}  }} { {% endcomment %} {% comment {% endraw %} {% endcomment %}"
    )

    assert_template_result("foobar", "foo{%comment%}comment{%endcomment%}bar")
    assert_template_result("foobar", "foo{% comment %}comment{% endcomment %}bar")
    assert_template_result("foobar", "foo{%comment%} comment {%endcomment%}bar")
    assert_template_result("foobar", "foo{% comment %} comment {% endcomment %}bar")

    assert_template_result("foo  bar", "foo {%comment%} {%endcomment%} bar")
    assert_template_result("foo  bar", "foo {%comment%}comment{%endcomment%} bar")
    assert_template_result("foo  bar", "foo {%comment%} comment {%endcomment%} bar")

    assert_template_result("foobar", "foo{%comment%}
                                     {%endcomment%}bar")
  end

  test :test_hyphenated_assign do
    assigns = %{"a-b" => "1"}
    assert_template_result("a-b:1 a-b:2", "a-b:{{a-b}} {%assign a-b = 2 %}a-b:{{a-b}}", assigns)
  end

  test :test_assign_with_colon_and_spaces do
    assigns = %{"var" => %{"a:b c" => %{"paged" => "1"}}}

    assert_template_result(
      "var2: 1",
      "{%assign var2 = var[\"a:b c\"].paged %}var2: {{var2}}",
      assigns
    )
  end

  test :test_capture do
    assigns = %{"var" => "content"}

    assert_template_result(
      "content foo content foo ",
      "{{ var2 }}{% capture var2 %}{{ var }} foo {% endcapture %}{{ var2 }}{{ var2 }}",
      assigns
    )
  end

  # test :test_capture_detects_bad_syntax do
  #   assert_raises(SyntaxError) do
  #     assert_template_result("content foo content foo ",
  #                            "{{ var2 }}{% capture %}{{ var }} foo {% endcapture %}{{ var2 }}{{ var2 }}",
  #                            %{"var" => "content" })
  #   end
  # end

  test :test_case do
    assigns = %{"condition" => 2}

    assert_template_result(
      " its 2 ",
      "{% case condition %}{% when 1 %} its 1 {% when 2 %} its 2 {% endcase %}",
      assigns
    )

    assigns = %{"condition" => 1}

    assert_template_result(
      " its 1 ",
      "{% case condition %}{% when 1 %} its 1 {% when 2 %} its 2 {% endcase %}",
      assigns
    )

    assigns = %{"condition" => 3}

    assert_template_result(
      "",
      "{% case condition %}{% when 1 %} its 1 {% when 2 %} its 2 {% endcase %}",
      assigns
    )

    assigns = %{"condition" => "string here"}

    assert_template_result(
      " hit ",
      "{% case condition %}{% when \"string here\" %} hit {% endcase %}",
      assigns
    )

    assigns = %{"condition" => "bad string here"}

    assert_template_result(
      "",
      "{% case condition %}{% when \"string here\" %} hit {% endcase %}",
      assigns
    )
  end

  test :test_case_with_else do
    assigns = %{"condition" => 5}

    assert_template_result(
      " hit ",
      "{% case condition %}{% when 5 %} hit {% else %} else {% endcase %}",
      assigns
    )

    assigns = %{"condition" => 6}

    assert_template_result(
      " else ",
      "{% case condition %}{% when 5 %} hit {% else %} else {% endcase %}",
      assigns
    )

    assigns = %{"condition" => 6}

    assert_template_result(
      " else ",
      "{% case condition %} {% when 5 %} hit {% else %} else {% endcase %}",
      assigns
    )
  end

  test :test_case_on_size do
    assert_template_result("", "{% case a.size %}{% when 1 %}1{% when 2 %}2{% endcase %}", %{
      "a" => []
    })

    assert_template_result("1", "{% case a.size %}{% when 1 %}1{% when 2 %}2{% endcase %}", %{
      "a" => [1]
    })

    assert_template_result("2", "{% case a.size %}{% when 1 %}1{% when 2 %}2{% endcase %}", %{
      "a" => [1, 1]
    })

    assert_template_result("", "{% case a.size %}{% when 1 %}1{% when 2 %}2{% endcase %}", %{
      "a" => [1, 1, 1]
    })

    assert_template_result("", "{% case a.size %}{% when 1 %}1{% when 2 %}2{% endcase %}", %{
      "a" => [1, 1, 1, 1]
    })

    assert_template_result("", "{% case a.size %}{% when 1 %}1{% when 2 %}2{% endcase %}", %{
      "a" => [1, 1, 1, 1, 1]
    })
  end

  test :test_case_on_size_with_else do
    assert_template_result(
      "else",
      "{% case a.size %}{% when 1 %}1{% when 2 %}2{% else %}else{% endcase %}",
      %{"a" => []}
    )

    assert_template_result(
      "1",
      "{% case a.size %}{% when 1 %}1{% when 2 %}2{% else %}else{% endcase %}",
      %{"a" => [1]}
    )

    assert_template_result(
      "2",
      "{% case a.size %}{% when 1 %}1{% when 2 %}2{% else %}else{% endcase %}",
      %{"a" => [1, 1]}
    )

    assert_template_result(
      "else",
      "{% case a.size %}{% when 1 %}1{% when 2 %}2{% else %}else{% endcase %}",
      %{"a" => [1, 1, 1]}
    )

    assert_template_result(
      "else",
      "{% case a.size %}{% when 1 %}1{% when 2 %}2{% else %}else{% endcase %}",
      %{"a" => [1, 1, 1, 1]}
    )

    assert_template_result(
      "else",
      "{% case a.size %}{% when 1 %}1{% when 2 %}2{% else %}else{% endcase %}",
      %{"a" => [1, 1, 1, 1, 1]}
    )
  end

  test :test_case_on_length_with_else do
    assert_template_result(
      "else",
      "{% case a.empty? %}{% when true %}true{% when false %}false{% else %}else{% endcase %}",
      %{}
    )

    assert_template_result(
      "false",
      "{% case false %}{% when true %}true{% when false %}false{% else %}else{% endcase %}",
      %{}
    )

    assert_template_result(
      "true",
      "{% case true %}{% when true %}true{% when false %}false{% else %}else{% endcase %}",
      %{}
    )

    assert_template_result(
      "else",
      "{% case NULL %}{% when true %}true{% when false %}false{% else %}else{% endcase %}",
      %{}
    )
  end

  test :test_assign_from_case do
    # Example from the shopify forums
    code =
      "{% case collection.handle %}{% when 'menswear-jackets' %}{% assign ptitle = 'menswear' %}{% when 'menswear-t-shirts' %}{% assign ptitle = 'menswear' %}{% else %}{% assign ptitle = 'womenswear' %}{% endcase %}{{ ptitle }}"

    template = Liquid.Template.parse(code)

    {:ok, result, _} =
      Template.render(template, %{"collection" => %{"handle" => "menswear-jackets"}})

    assert "menswear" == result

    {:ok, result, _} =
      Template.render(template, %{"collection" => %{"handle" => "menswear-t-shirts"}})

    assert "menswear" == result
    {:ok, result, _} = Template.render(template, %{"collection" => %{"handle" => "x"}})
    assert "womenswear" == result
    {:ok, result, _} = Template.render(template, %{"collection" => %{"handle" => "y"}})
    assert "womenswear" == result
    {:ok, result, _} = Template.render(template, %{"collection" => %{"handle" => "z"}})
    assert "womenswear" == result
  end

  test :test_case_when_or do
    code =
      "{% case condition %}{% when 1 or 2 or 3 %} its 1 or 2 or 3 {% when 4 %} its 4 {% endcase %}"

    assert_template_result(" its 1 or 2 or 3 ", code, %{"condition" => 1})
    assert_template_result(" its 1 or 2 or 3 ", code, %{"condition" => 2})
    assert_template_result(" its 1 or 2 or 3 ", code, %{"condition" => 3})
    assert_template_result(" its 4 ", code, %{"condition" => 4})
    assert_template_result("", code, %{"condition" => 5})

    code =
      "{% case condition %}{% when 1 or \"string\" or null %} its 1 or 2 or 3 {% when 4 %} its 4 {% endcase %}"

    assert_template_result(" its 1 or 2 or 3 ", code, %{"condition" => 1})
    assert_template_result(" its 1 or 2 or 3 ", code, %{"condition" => "string"})
    assert_template_result(" its 1 or 2 or 3 ", code, %{"condition" => nil})
    assert_template_result("", code, %{"condition" => "something else"})
  end

  test :test_case_when_comma do
    code =
      "{% case condition %}{% when 1, 2, 3 %} its 1 or 2 or 3 {% when 4 %} its 4 {% endcase %}"

    assert_template_result(" its 1 or 2 or 3 ", code, %{"condition" => 1})
    assert_template_result(" its 1 or 2 or 3 ", code, %{"condition" => 2})
    assert_template_result(" its 1 or 2 or 3 ", code, %{"condition" => 3})
    assert_template_result(" its 4 ", code, %{"condition" => 4})
    assert_template_result("", code, %{"condition" => 5})

    code =
      "{% case condition %}{% when 1, \"string\", null %} its 1 or 2 or 3 {% when 4 %} its 4 {% endcase %}"

    assert_template_result(" its 1 or 2 or 3 ", code, %{"condition" => 1})
    assert_template_result(" its 1 or 2 or 3 ", code, %{"condition" => "string"})
    assert_template_result(" its 1 or 2 or 3 ", code, %{"condition" => nil})
    assert_template_result("", code, %{"condition" => "something else"})
  end

  test :test_assign do
    assert_template_result("variable", "{% assign a = \"variable\"%}{{a}}")
  end

  test :test_assign_unassigned do
    assigns = %{"var" => "content"}

    assert_template_result(
      "var2:  var2:content",
      "var2:{{var2}} {%assign var2 = var%} var2:{{var2}}",
      assigns
    )
  end

  test :test_assign_an_empty_string do
    assert_template_result("", "{% assign a = \"\"%}{{a}}")
  end

  test :test_assign_is_global do
    assert_template_result(
      "variable",
      "{%for i in (1..2) %}{% assign a = \"variable\"%}{% endfor %}{{a}}"
    )
  end

  # test :test_case_detects_bad_syntax do
  #   assert_raises(SyntaxError) do
  #     assert_template_result("",  "{% case false %}{% when %}true{% endcase %}", {})
  #   end
  #
  #   assert_raises(SyntaxError) do
  #     assert_template_result("",  "{% case false %}{% huh %}true{% endcase %}", {})
  #   end
  #
  # end

  test :test_cycle do
    assert_template_result("one", "{%cycle \"one\", \"two\"%}")
    assert_template_result("one two", "{%cycle \"one\", \"two\"%} {%cycle \"one\", \"two\"%}")
    assert_template_result(" two", "{%cycle \"\", \"two\"%} {%cycle \"\", \"two\"%}")

    assert_template_result(
      "one two one",
      "{%cycle \"one\", \"two\"%} {%cycle \"one\", \"two\"%} {%cycle \"one\", \"two\"%}"
    )

    assert_template_result(
      "text-align: left text-align: right",
      "{%cycle \"text-align: left\", \"text-align: right\" %} {%cycle \"text-align: left\", \"text-align: right\"%}"
    )
  end

  test :test_multiple_cycles do
    assert_template_result(
      "1 2 1 1 2 3 1",
      "{%cycle 1,2%} {%cycle 1,2%} {%cycle 1,2%} {%cycle 1,2,3%} {%cycle 1,2,3%} {%cycle 1,2,3%} {%cycle 1,2,3%}"
    )
  end

  test :test_multiple_named_cycles do
    assert_template_result(
      "one one two two one one",
      "{%cycle 1: \"one\", \"two\" %} {%cycle 2: \"one\", \"two\" %} {%cycle 1: \"one\", \"two\" %} {%cycle 2: \"one\", \"two\" %} {%cycle 1: \"one\", \"two\" %} {%cycle 2: \"one\", \"two\" %}"
    )
  end

  test :test_multiple_named_cycles_with_names_from_context do
    assigns = %{"var1" => 1, "var2" => 2}

    assert_template_result(
      "one one two two one one",
      "{%cycle var1: \"one\", \"two\" %} {%cycle var2: \"one\", \"two\" %} {%cycle var1: \"one\", \"two\" %} {%cycle var2: \"one\", \"two\" %} {%cycle var1: \"one\", \"two\" %} {%cycle var2: \"one\", \"two\" %}",
      assigns
    )
  end

  test :test_size_of_array do
    assigns = %{"array" => [1, 2, 3, 4]}
    assert_template_result("array has 4 elements", "array has {{ array.size }} elements", assigns)
  end

  test :test_size_of_hash do
    assigns = %{"hash" => %{"a" => 1, "b" => 2, "c" => 3, "d" => 4}}
    assert_template_result("hash has 4 elements", "hash has {{ hash.size }} elements", assigns)
  end

  test :test_size_of_string do
    assigns = %{"string" => "foo"}

    assert_template_result(
      "string has 3 characters",
      "string has {{ string.size }} characters",
      assigns
    )
  end

  test :test_illegal_symbols do
    assert_template_result("", "{% if true == empty %}?{% endif %}", %{})
    assert_template_result("", "{% if true == null %}?{% endif %}", %{})
    assert_template_result("", "{% if empty == true %}?{% endif %}", %{})
    assert_template_result("", "{% if null == true %}?{% endif %}", %{})
  end

  test :test_ifchanged do
    assigns = %{"array" => [1, 1, 2, 2, 3, 3]}

    assert_template_result(
      "123",
      "{%for item in array%}{%ifchanged%}{{item}}{% endifchanged %}{%endfor%}",
      assigns
    )

    assigns = %{"array" => [1, 1, 1, 1]}

    assert_template_result(
      "1",
      "{%for item in array%}{%ifchanged%}{{item}}{% endifchanged %}{%endfor%}",
      assigns
    )
  end

  test :inner_ifchanged_name_overlap do
    assert_template_result(
      "145624563456",
      "{%for item in (1..3)%}{%ifchanged%}{{item}}{%for item in (4..6)%}{{item}}{%endfor%}{% endifchanged %}{%endfor%}"
    )
  end

  test :test_multiline_tag do
    assert_template_result("0 1 2 3", "0{% for i in (1..3) %} {{ i }}{% endfor %}")
    assert_template_result("0 1 2 3", "0{%\nfor i in (1..3)\n%} {{\ni\n}}{%\nendfor\n%}")
  end

  defp assert_template_result(expected, markup, assigns \\ %{}) do
    assert_result(expected, markup, assigns)
  end

  defp assert_result(expected, markup, assigns) do
    t = Template.parse(markup)
    {:ok, rendered, _} = Template.render(t, assigns)
    assert rendered == expected
  end
end
