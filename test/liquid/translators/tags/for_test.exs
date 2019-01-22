defmodule Liquid.Translators.Tags.ForTest do
  use ExUnit.Case
  import Liquid.Helpers

  test "for translate new AST to old AST" do
    params = %{"array" => [1, 1, 2, 2, 3, 3], "repeat_array" => [1, 1, 1, 1]}

    [
      "{%for item in array%}{%ifchanged%}{{item}}{% endifchanged %}{%endfor%}",
      "{%for i in (1..2) %}{% assign a = \"variable\"%}{% endfor %}{{a}}",
      "{%for item in repeat_array%}{%ifchanged%}{{item}}{% endifchanged %}{%endfor%}",
      "{%for item in (1..3)%}{%ifchanged%}{{item}}{%for item in (4..6)%}{{item}}{%endfor%}{% endifchanged %}{%endfor%}",
      "0{% for i in (1..3) %} {{ i }}{% endfor %}",
      "0{%\nfor i in (1..3)\n%} {{\ni\n}}{%\nendfor\n%}",
      """
        {%for val in array%}
          {{forloop.name}}-
          {{forloop.index}}-
          {{forloop.length}}-
          {{forloop.index0}}-
          {{forloop.rindex}}-
          {{forloop.rindex0}}-
        {{forloop.first}}-{{forloop.last}}-{{val}}{%endfor%}
      """,
      "{%for item in array%}\r{% if forloop.first %}\r+{% else %}\n-\r{% endif %}{%endfor%}",
      """
        {%for item in array%}
        yo
        {%endfor%}
      """,
      "{%for item in array reversed %}{{item}}{%endfor%}",
      "{%for item in (1..3) %} {{item}} {%endfor%}",
      "{%for item in array%} {{item}} {%endfor%}",
      "{% for item in array %}{{item}}{% endfor %}",
      "{%for item in array%}{{item}}{%endfor%}",
      "{%for i in array limit:2 %}{{ i }}{%endfor%}",
      "{%for i in array limit:4 %}{{ i }}{%endfor%}",
      "{%for i in array limit:4 offset:2 %}{{ i }}{%endfor%}",
      "{%for i in array limit: 4 offset: 2 %}{{ i }}{%endfor%}",
      "{%for item in array%}{%for i in item%}{{ i }}{%endfor%}{%endfor%}",
      "{% for i in array %}{% break %}{% endfor %}",
      "{% for i in array %}{{ i }}{% break %}{% endfor %}",
      "{% for i in array %}{% break %}{{ i }}{% endfor %}",
      "{% for i in array %}{{ i }}{% if i > 3 %}{% break %}{% endif %}{% endfor %}"
    ]
    |> Enum.each(fn tag ->
      test_ast_translation(tag, params)
    end)
  end

  test "for translate advanced test" do
    [
      {"{% for item in array %}{% for i in item %}{{ i }}{% endfor %}{% endfor %}",
       %{"array" => [[1, 2], [3, 4], [5, 6]]}},
      {"{%for i in array limit: limit offset: offset %}{{ i }}{%endfor%}",
       %{"array" => [1, 2, 3, 4, 5, 6, 7, 8, 9, 0], "limit" => 2, "offset" => 2}},
      {"""
         {%for i in array.items limit:3 %}{{i}}{%endfor%}
           next
         {%for i in array.items offset:continue limit:3 %}{{i}}{%endfor%}
           next
         {%for i in array.items offset:continue limit:3 offset:1000 %}{{i}}{%endfor%}
       """, %{"array" => %{"items" => [1, 2, 3, 4, 5, 6, 7, 8, 9, 0]}}},
      {"""
         {%for i in array.items limit: 3 %}{{i}}{%endfor%}
         next
         {%for i in array.items offset:continue limit: 3 %}{{i}}{%endfor%}
         next
         {%for i in array.items offset:continue limit: 3 %}{{i}}{%endfor%}
       """, %{"array" => %{"items" => [1, 2, 3, 4, 5, 6, 7, 8, 9, 0]}}},
      {"""
         {%for i in array.items limit:3 %}{{i}}{%endfor%}
         next
         {%for i in array.items offset:continue limit:3 %}{{i}}{%endfor%}
         next
         {%for i in array.items offset:continue limit:1000 %}{{i}}{%endfor%}
       """, %{"array" => %{"items" => [1, 2, 3, 4, 5, 6, 7, 8, 9, 0]}}},
      {"""
         {%for i in array.items limit:3 %}{{i}}{%endfor%}
         next
         {%for i in array.items offset:continue limit:3 %}{{i}}{%endfor%}
         next{%for i in array.items offset:continue limit:3 offset:1000 %}{{i}}{%endfor%}
       """, %{"array" => %{"items" => [1, 2, 3, 4, 5, 6, 7, 8, 9, 0]}}}
    ]
    |> Enum.each(fn {markup, params} ->
      test_ast_translation(markup, params)
    end)
  end
end
