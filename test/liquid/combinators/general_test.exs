defmodule Liquid.Combinators.GeneralTest do
  use ExUnit.Case
  import Liquid.Helpers

  defmodule Parser do
    import NimbleParsec
    alias Liquid.Combinators.{General, LexicalToken}
    defparsec(:whitespace, General.whitespace())
    defparsec(:ignore_whitespaces, General.ignore_whitespaces())
    defparsec(:start_tag, General.start_tag())
    defparsec(:end_tag, General.end_tag())
    defparsec(:start_variable, General.start_variable())
    defparsec(:end_variable, General.end_variable())
    defparsec(:variable_definition_for_assignment, General.variable_definition_for_assignment())
    defparsec(:variable_name_for_assignment, General.variable_name_for_assignment())
    defparsec(:variable_definition, General.variable_definition())
    defparsec(:variable_name, General.variable_name())
    defparsec(:filter, General.filter())
    defparsec(:filter_param, General.filter_param())
    defparsec(:filters, General.filters())
    defparsec(:liquid_variable, General.liquid_variable())
    defparsec(:value, LexicalToken.value())
    defparsec(:value_definition, LexicalToken.value_definition())
    defparsec(:object_property, LexicalToken.object_property())
    defparsec(:variable_value, LexicalToken.variable_value())
    defparsec(:object_value, LexicalToken.object_value())
    defparsec(:variable_part, LexicalToken.variable_part())
  end

  test "whitespace must parse 0x0020 and 0x0009" do
    test_combinator(" ", &Parser.whitespace/1, ' ')
    test_combinator("\t", &Parser.whitespace/1, '\t')
    test_combinator("\n", &Parser.whitespace/1, '\n')
    test_combinator("\r", &Parser.whitespace/1, '\r')
  end

  test "extra_spaces ignore all :whitespaces" do
    test_combinator("      ", &Parser.ignore_whitespaces/1, [])
    test_combinator("    \t\t\t  ", &Parser.ignore_whitespaces/1, [])
    test_combinator("", &Parser.ignore_whitespaces/1, [])
  end

  test "start_tag" do
    test_combinator("{%", &Parser.start_tag/1, [])
    test_combinator("{%   \t   \t", &Parser.start_tag/1, [])
  end

  test "end_tag" do
    test_combinator("%}", &Parser.end_tag/1, [])
    test_combinator("   \t   \t%}", &Parser.end_tag/1, [])
  end

  test "start_variable" do
    test_combinator("{{", &Parser.start_variable/1, [])
    test_combinator("{{   \t   \t", &Parser.start_variable/1, [])
  end

  test "end_variable" do
    test_combinator("}}", &Parser.end_variable/1, [])
    test_combinator("   \t   \t}}", &Parser.end_variable/1, [])
  end

  test "variable name valid" do
    valid_names = ~w(v v1 _v1 _1 v-1 v- v_ a)

    Enum.each(valid_names, fn n ->
      test_combinator(n, &Parser.variable_name/1, variable_name: n)
    end)
  end

  test "variable name invalid" do
    invalid_names = ~w(. .a @a #a ^a 好a ,a -a)

    Enum.each(invalid_names, fn n ->
      test_combinator_internal_error(n, &Parser.variable_name/1)
    end)
  end

  test "variable with filters and params" do
    test_combinator(
      "{{ var.var1[0][0].var2[3] | filter1 | f2: 1 | f3: 2 | f4: 2, 3 }}",
      &Parser.liquid_variable/1,
      liquid_variable: [
        variable: [
          parts: [
            part: "var",
            part: "var1",
            index: 0,
            index: 0,
            part: "var2",
            index: 3
          ],
          filters: [
            filter: ["filter1"],
            filter: ["f2", {:params, [value: 1]}],
            filter: ["f3", {:params, [value: 2]}],
            filter: ["f4", {:params, [value: 2, value: 3]}]
          ]
        ]
      ]
    )
  end

  defp test_combinator_internal_error(markup, combiner) do
    {:error, _, _, _, _, _} = combiner.(markup)
    assert true
  end
end
