defmodule Liquid.Combinator.Tags.ForTest do
  use ExUnit.Case

  import Liquid.Helpers
  alias Liquid.NimbleParser, as: Parser

  test "for tag: basic tag structures" do
    tags = [
      "{% for item in array %}{% endfor %}",
      "{%for item in array%}{%endfor%}",
      "{%     for     item    in     array    %}{%    endfor    %}",
    ]

    Enum.each(
      tags,
      fn tag ->
        test_combinator(
          tag,
          &Parser.for/1,
          [
            {
              :for,
              [
                for_conditions: [
                  variable_name: "item",
                  value: "array"
                ],
                for_sentences: [""]
              ]
            },
            ""
          ]
        )
      end
    )

  end

  test "for tag: else tag structures" do
    tags = [
      "{% for item in array %}{% else %}{% endfor %}",
      "{%for item in array%}{%else%}{%endfor%}",
      "{%     for     item    in     array    %}{%   else    %}{%    endfor    %}",
    ]

    Enum.each(
      tags,
      fn tag ->
        test_combinator(
          tag,
          &Parser.for/1,
          [
            {
              :for,
              [
                for_conditions: [
                  variable_name: "item",
                  value: "array"
                ],
                for_sentences: [""],
                else_sentences: [""]
              ]
            },
            ""
          ]
        )
      end
    )

  end

  test "for tag: limit parameter" do
    tags = [
      "{% for item in array limit:2 %}{% else %}{% endfor %}",
      "{%for item in array limit:2%}{%else%}{%endfor%}",
      "{%     for     item    in     array  limit:2  %}{%   else    %}{%    endfor    %}",
      "{%     for     item    in     array  limit: 2  %}{%   else    %}{%    endfor    %}"
    ]

    Enum.each(
      tags,
      fn tag ->
        test_combinator(
          tag,
          &Parser.for/1,
          [
            {
              :for,
              [
                for_conditions: [
                  variable_name: "item",
                  value: "array",
                  limit_param: [2]
                ],
                for_sentences: [""],
                else_sentences: [""]
              ]
            },
            ""
          ]
        )
      end
    )
  end



  test "for tag: offset parameter" do
    tags = [
      "{% for item in array offset:2 %}{% else %}{% endfor %}",
      "{%for item in array offset:2%}{%else%}{%endfor%}",
      "{%     for     item    in     array  offset:2  %}{%   else    %}{%    endfor    %}"
    ]

    Enum.each(
      tags,
      fn tag ->
        test_combinator(
          tag,
          &Parser.for/1,
          [
            {
              :for,
              [
                for_conditions: [
                  variable_name: "item",
                  value: "array",
                  offset_param: [2]
                ],
                for_sentences: [""],
                else_sentences: [""]
              ]
            },
            ""
          ]
        )
      end
    )
  end

  test "for tag: reversed parameter" do
    tags = [
      "{% for item in array reversed %}{% else %}{% endfor %}",
      "{%for item in array reversed%}{%else%}{%endfor%}",
      "{%     for     item    in     array  reversed  %}{%   else    %}{%    endfor    %}",
    ]

    Enum.each(
      tags,
      fn tag ->
        test_combinator(
          tag,
          &Parser.for/1,
          [
            {
              :for,
              [
                for_conditions: [
                  variable_name: "item",
                  value: "array",
                  reversed_param: []
                ],
                for_sentences: [""],
                else_sentences: [""]
              ]
            },
            ""
          ]
        )
      end
    )
  end

  test "for tag: range parameter" do
    tags = [
      "{% for i in (1..10) %}{{ i }}{% endfor %}",
      "{%for i in (1..10)%}{{ i }}{% endfor %}",
      "{%     for     i     in     (1..10)      %}{{ i }}{%     endfor     %}",
    ]

    Enum.each(
      tags,
      fn tag ->
        test_combinator(
          tag,
          &Parser.for/1,
          [
            {
              :for,
              [
                for_conditions: [
                  variable_name: "i",
                  range_value: ["(1..10)"]
                ],
                for_sentences: ["", {:variable, [variable_name: "i"]}, ""]
              ]
            },
            ""
          ]
        )
      end
    )
  end

  test "for tag: range with variables" do
    test_combinator(
      "{% for i in (my_var..10) %}{{ i }}{% endfor %}",
      &Parser.for/1,
      [
        {
          :for,
          [
            for_conditions: [
              variable_name: "i",
              range_value: ["(my_var..10)"]
            ],
            for_sentences: ["", {:variable, [variable_name: "i"]}, ""]
          ]
        },
        ""
      ]
    )
  end

  test "for tag: break tag" do
    test_combinator(
    "{% for i in (my_var..10) %}{{ i }}{% break %}{% endfor %}",
      &Parser.for/1,
      [
        {:for,
          [
            for_conditions: [variable_name: "i", range_value: ["(my_var..10)"]],
            for_sentences: [
              "",
              {:variable, [variable_name: "i"]},
              "",
              {:break, []},
              ""
            ]
          ]},
        ""
      ]
    )
  end

  test "for tag: continue tag" do
    test_combinator(
      "{% for i in (1..my_var) %}{{ i }}{% continue %}{% endfor %}",
      &Parser.for/1,
      [
        {:for,
          [
            for_conditions: [variable_name: "i", range_value: ["(1..my_var)"]],
            for_sentences: [
              "",
              {:variable, [variable_name: "i"]},
              "",
              {:continue, []},
              ""
            ]
          ]},
        ""
      ]
    )
  end

  test "for tag: invalid tag structure and variable values" do
    test_combinator_error("{% for i in (my_var..10) %}{{ i }}{% else %}{% else %}{% endfor %}", &Parser.for/1)
    test_combinator_error("{% for i in (my_var..product.title[2]) %}{{ i }}{% else %}{% endfor %}", &Parser.for/1)
    test_combinator_error("{% for i in products limit: a %}{{ i }}{% else %}{% endfor %}", &Parser.for/1)
  end

end

#
#Code.require_file("../../test_helper.exs", __ENV__.file)
#
#defmodule ForElseTagTest do
#  use ExUnit.Case
#
#  alias Liquid.Template, as: Template
#
#  setup_all do
#    Liquid.start()
#    :ok
#  end
#
#  test :for_block do
#    assert_result(" yo  yo  yo  yo ", "{%for item in array%} yo {%endfor%}", %{
#      "array" => [1, 2, 3, 4]
#    })
#
#    assert_result("yoyo", "{%for item in array%}yo{%endfor%}", %{"array" => [1, 2]})
#    assert_result(" yo ", "{%for item in array%} yo {%endfor%}", %{"array" => [1]})
#    assert_result("", "{%for item in array%}{%endfor%}", %{"array" => [1, 2]})
#
#    expected = """
#
#      yo
#
#      yo
#
#      yo
#
#    """
#
#    template = """
#    {%for item in array%}
#      yo
#    {%endfor%}
#    """
#
#    assert_result(expected, template, %{"array" => [1, 2, 3]})
#  end
#
#  test :for_reversed do
#    assigns = %{"array" => [1, 2, 3]}
#    assert_result("321", "{%for item in array reversed %}{{item}}{%endfor%}", assigns)
#  end
#
#  test :for_with_range do
#    assert_result(" 1  2  3 ", "{%for item in (1..3) %} {{item}} {%endfor%}", %{})
#
#    assert_raise(ArgumentError, fn ->
#      markup = "{% for i in (a..2) %}{% endfor %}'"
#      t = Template.parse(markup)
#      Template.render(t, %{"a" => [1, 2]})
#    end)
#
#    assert_template_result(" 0  1  2  3 ", "{% for item in (a..3) %} {{item}} {% endfor %}", %{
#      "a" => "invalid integer"
#    })
#  end
#
#  test :for_with_variable do
#    assert_result(" 1  2  3 ", "{%for item in array%} {{item}} {%endfor%}", %{
#      "array" => [1, 2, 3]
#    })
#
#    assert_result("123", "{%for item in array%}{{item}}{%endfor%}", %{"array" => [1, 2, 3]})
#    assert_result("123", "{% for item in array %}{{item}}{% endfor %}", %{"array" => [1, 2, 3]})
#
#    assert_result("abcd", "{%for item in array%}{{item}}{%endfor%}", %{
#      "array" => ["a", "b", "c", "d"]
#    })
#
#    assert_result("a b c", "{%for item in array%}{{item}}{%endfor%}", %{
#      "array" => ["a", " ", "b", " ", "c"]
#    })
#
#    assert_result("abc", "{%for item in array%}{{item}}{%endfor%}", %{
#      "array" => ["a", "", "b", "", "c"]
#    })
#  end
#
#  test :for_helpers do
#    assigns = %{"array" => [1, 2, 3]}
#
#    assert_result(
#      " 1/3  2/3  3/3 ",
#      "{%for item in array%} {{forloop.index}}/{{forloop.length}} {%endfor%}",
#      assigns
#    )
#
#    assert_result(" 1  2  3 ", "{%for item in array%} {{forloop.index}} {%endfor%}", assigns)
#    assert_result(" 0  1  2 ", "{%for item in array%} {{forloop.index0}} {%endfor%}", assigns)
#    assert_result(" 2  1  0 ", "{%for item in array%} {{forloop.rindex0}} {%endfor%}", assigns)
#    assert_result(" 3  2  1 ", "{%for item in array%} {{forloop.rindex}} {%endfor%}", assigns)
#
#    assert_result(
#      " true  false  false ",
#      "{%for item in array%} {{forloop.first}} {%endfor%}",
#      assigns
#    )
#
#    assert_result(
#      " false  false  true ",
#      "{%for item in array%} {{forloop.last}} {%endfor%}",
#      assigns
#    )
#  end
#
#  test :for_and_if do
#    assigns = %{"array" => [1, 2, 3]}
#
#    assert_result(
#      "+--",
#      "{%for item in array%}{% if forloop.first %}+{% else %}-{% endif %}{%endfor%}",
#      assigns
#    )
#  end
#
#  test :for_else do
#    assert_result("+++", "{%for item in array%}+{%else%}-{%endfor%}", %{"array" => [1, 2, 3]})
#    assert_result("-", "{%for item in array%}+{%else%}-{%endfor%}", %{"array" => []})
#    assert_result("-", "{%for item in array%}+{%else%}-{%endfor%}", %{"array" => nil})
#  end
#
#  test :limiting do
#    assigns = %{"array" => [1, 2, 3, 4, 5, 6, 7, 8, 9, 0]}
#    assert_result("12", "{%for i in array limit:2 %}{{ i }}{%endfor%}", assigns)
#    assert_result("1234", "{%for i in array limit:4 %}{{ i }}{%endfor%}", assigns)
#    assert_result("3456", "{%for i in array limit:4 offset:2 %}{{ i }}{%endfor%}", assigns)
#    assert_result("3456", "{%for i in array limit: 4 offset: 2 %}{{ i }}{%endfor%}", assigns)
#  end
#
#  test :dynamic_variable_limiting do
#    assigns = %{"array" => [1, 2, 3, 4, 5, 6, 7, 8, 9, 0], "limit" => 2, "offset" => 2}
#
#    assert_result(
#      "34",
#      "{%for i in array limit: limit offset: offset %}{{ i }}{%endfor%}",
#      assigns
#    )
#  end
#
#  test :nested_for do
#    assigns = %{"array" => [[1, 2], [3, 4], [5, 6]]}
#
#    assert_result(
#      "123456",
#      "{%for item in array%}{%for i in item%}{{ i }}{%endfor%}{%endfor%}",
#      assigns
#    )
#  end
#
#  test :offset_only do
#    assigns = %{"array" => [1, 2, 3, 4, 5, 6, 7, 8, 9, 0]}
#    assert_result("890", "{%for i in array offset:7 %}{{ i }}{%endfor%}", assigns)
#  end
#
#  test :pause_resume do
#    assigns = %{"array" => %{"items" => [1, 2, 3, 4, 5, 6, 7, 8, 9, 0]}}
#
#    markup = """
#    {%for i in array.items limit: 3 %}{{i}}{%endfor%}
#    next
#    {%for i in array.items offset:continue limit: 3 %}{{i}}{%endfor%}
#    next
#    {%for i in array.items offset:continue limit: 3 %}{{i}}{%endfor%}
#    """
#
#    expected = """
#    123
#    next
#    456
#    next
#    789
#    """
#
#    assert_result(expected, markup, assigns)
#  end
#
#  test :pause_resume_limit do
#    assigns = %{"array" => %{"items" => [1, 2, 3, 4, 5, 6, 7, 8, 9, 0]}}
#
#    markup = """
#    {%for i in array.items limit:3 %}{{i}}{%endfor%}
#    next
#    {%for i in array.items offset:continue limit:3 %}{{i}}{%endfor%}
#    next
#    {%for i in array.items offset:continue limit:1 %}{{i}}{%endfor%}
#    """
#
#    expected = """
#    123
#    next
#    456
#    next
#    7
#    """
#
#    assert_result(expected, markup, assigns)
#  end
#
#  test :pause_resume_BIG_limit do
#    assigns = %{"array" => %{"items" => [1, 2, 3, 4, 5, 6, 7, 8, 9, 0]}}
#
#    markup = """
#    {%for i in array.items limit:3 %}{{i}}{%endfor%}
#    next
#    {%for i in array.items offset:continue limit:3 %}{{i}}{%endfor%}
#    next
#    {%for i in array.items offset:continue limit:1000 %}{{i}}{%endfor%}
#    """
#
#    expected = """
#    123
#    next
#    456
#    next
#    7890
#    """
#
#    assert_result(expected, markup, assigns)
#  end
#
#  test :pause_resume_BIG_offset do
#    assigns = %{"array" => %{"items" => [1, 2, 3, 4, 5, 6, 7, 8, 9, 0]}}
#
#    markup = """
#    {%for i in array.items limit:3 %}{{i}}{%endfor%}
#    next
#    {%for i in array.items offset:continue limit:3 %}{{i}}{%endfor%}
#    next{%for i in array.items offset:continue limit:3 offset:1000 %}{{i}}{%endfor%}
#    """
#
#    expected = """
#    123
#    next
#    456
#    next
#    """
#
#    assert_result(expected, markup, assigns)
#  end
#
#  test :for_with_break do
#    assigns = %{"array" => %{"items" => [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]}}
#
#    markup = "{% for i in array.items %}{% break %}{% endfor %}"
#    expected = ""
#    assert_result(expected, markup, assigns)
#
#    markup = "{% for i in array.items %}{{ i }}{% break %}{% endfor %}"
#    expected = "1"
#    assert_result(expected, markup, assigns)
#
#    markup = "{% for i in array.items %}{% break %}{{ i }}{% endfor %}"
#    expected = ""
#    assert_result(expected, markup, assigns)
#
#    markup = "{% for i in array.items %}{{ i }}{% if i > 3 %}{% break %}{% endif %}{% endfor %}"
#    expected = "1234"
#    assert_result(expected, markup, assigns)
#
#    # test break does nothing when unreached
#    assigns = %{"array" => %{"items" => [1, 2, 3, 4, 5]}}
#
#    markup =
#      "{% for i in array.items %}{% if i == 9999 %}{% break %}{% endif %}{{ i }}{% endfor %}"
#
#    expected = "12345"
#    assert_result(expected, markup, assigns)
#  end
#
#  test :for_with_loop_inside_loop do
#    # tests to ensure it only breaks out of the local for loop
#    # and not all of them.
#    assigns = %{"array" => [[1, 2], [3, 4], [5, 6]]}
#
#    markup =
#      "{% for item in array %}" <>
#      "{% for i in item %}" <> "{{ i }}" <> "{% endfor %}" <> "{% endfor %}"
#
#    expected = "123456"
#    assert_result(expected, markup, assigns)
#  end
#
#  test :for_with_break_inside_loop do
#    # tests to ensure it only breaks out of the local for loop
#    # and not all of them.
#    assigns = %{"array" => [[1, 2], [3, 4], [5, 6]]}
#
#    markup =
#      "{% for item in array %}" <>
#      "{% for i in item %}" <>
#      "{% if i == 1 %}" <>
#      "{% break %}" <> "{% endif %}" <> "{{ i }}" <> "{% endfor %}" <> "{% endfor %}"
#
#    expected = "3456"
#    assert_result(expected, markup, assigns)
#  end
#
#  test :for_with_continue do
#    assigns = %{"array" => %{"items" => [1, 2, 3, 4, 5]}}
#
#    markup = "{% for i in array.items %}{% continue %}{% endfor %}"
#    expected = ""
#    assert_result(expected, markup, assigns)
#
#    markup = "{% for i in array.items %}{{ i }}{% continue %}{% endfor %}"
#    expected = "12345"
#    assert_result(expected, markup, assigns)
#
#    markup = "{% for i in array.items %}{% continue %}{{ i }}{% endfor %}"
#    expected = ""
#    assert_result(expected, markup, assigns)
#
#    markup =
#      "{% for i in array.items %}{% if i > 3 %}{% continue %}{% endif %}{{ i }}{% endfor %}"
#
#    expected = "123"
#    assert_result(expected, markup, assigns)
#
#    markup =
#      "{% for i in array.items %}{% if i == 3 %}{% continue %}{% else %}{{ i }}{% endif %}{% endfor %}"
#
#    expected = "1245"
#    assert_result(expected, markup, assigns)
#
#    # tests to ensure it only continues the local for loop and not all of them.
#    assigns = %{"array" => [[1, 2], [3, 4], [5, 6]]}
#
#    markup =
#      "{% for item in array %}" <>
#      "{% for i in item %}" <>
#      "{% if i == 1 %}" <>
#      "{% continue %}" <> "{% endif %}" <> "{{ i }}" <> "{% endfor %}" <> "{% endfor %}"
#
#    expected = "23456"
#    assert_result(expected, markup, assigns)
#
#    # test continue does nothing when unreached
#    assigns = %{"array" => %{"items" => [1, 2, 3, 4, 5]}}
#
#    markup =
#      "{% for i in array.items %}{% if i == 9999 %}{% continue %}{% endif %}{{ i }}{% endfor %}"
#
#    expected = "12345"
#    assert_result(expected, markup, assigns)
#  end
#
#  test :for_tag_string do
#    # test continue does nothing when unreached
#    assigns = %{"array" => %{"items" => [1, 2, 3, 4, 5]}}
#
#    markup =
#      "{% for i in array.items %}{% if i == 9999 %}{% continue %}{% endif %}{{ i }}{% endfor %}"
#
#    expected = "12345"
#    assert_result(expected, markup, assigns)
#
#    assert_result("test string", "{%for val in string%}{{val}}{%endfor%}", %{
#      "string" => "test string"
#    })
#
#    assert_result("test string", "{%for val in string limit:1%}{{val}}{%endfor%}", %{
#      "string" => "test string"
#    })
#
#    assert_result(
#      "val-string-1-1-0-1-0-true-true-test string",
#      "{%for val in string%}" <>
#      "{{forloop.name}}-" <>
#      "{{forloop.index}}-" <>
#      "{{forloop.length}}-" <>
#      "{{forloop.index0}}-" <>
#      "{{forloop.rindex}}-" <>
#      "{{forloop.rindex0}}-" <>
#      "{{forloop.first}}-" <> "{{forloop.last}}-" <> "{{val}}{%endfor%}",
#      %{"string" => "test string"}
#    )
#  end
#
#  test :blank_string_not_iterable do
#    assert_result("", "{% for char in characters %}I WILL NOT BE OUTPUT{% endfor %}", %{
#      "characters" => ""
#    })
#  end
#
#  defp assert_template_result(expected, markup, assigns) do
#    assert_result(expected, markup, assigns)
#  end
#
#  defp assert_result(expected, markup, assigns) do
#    t = Template.parse(markup)
#    {:ok, rendered, _} = Template.render(t, assigns)
#    assert rendered == expected
#  end
#end
