defmodule Liquid.Combinators.Tags.CycleTest do
  use ExUnit.Case
  import Liquid.Helpers

  test "cycle tag with 2 values" do
    test_parse(
      "{%cycle \"one\", \"two\"%}",
      cycle: [values: ["one", "two"]]
    )
  end

  test "cycle tag 2 times" do
    test_parse("{%cycle \"one\", \"two\"%} {%cycle \"one\", \"two\"%}", [
      {:cycle, [values: ["one", "two"]]},
      " ",
      {:cycle, [values: ["one", "two"]]}
    ])
  end

  test "cycle tag with quoted blanks" do
    test_parse("{%cycle \"\", \"two\"%} {%cycle \"\", \"two\"%}", [
      {:cycle, [values: ["", "two"]]},
      " ",
      {:cycle, [values: ["", "two"]]}
    ])
  end

  test "cycle tag 3 times" do
    test_parse(
      "{%cycle \"one\", \"two\"%} {%cycle \"one\", \"two\"%} {%cycle \"one\", \"two\"%}",
      [
        {:cycle, [values: ["one", "two"]]},
        " ",
        {:cycle, [values: ["one", "two"]]},
        " ",
        {:cycle, [values: ["one", "two"]]}
      ]
    )
  end

  test "cycle with html values" do
    test_parse(
      "{%cycle \"text-align: left\", \"text-align: right\" %} {%cycle \"text-align: left\", \"text-align: right\"%}",
      [
        {:cycle, [values: ["text-align: left", "text-align: right"]]},
        " ",
        {:cycle, [values: ["text-align: left", "text-align: right"]]}
      ]
    )
  end

  test "cycle tag with integers" do
    test_parse(
      "{%cycle 1,2%} {%cycle 1,2%} {%cycle 1,2%} {%cycle 1,2,3%} {%cycle 1,2,3%} {%cycle 1,2,3%} {%cycle 1,2,3%}",
      [
        {:cycle, [values: [1, 2]]},
        " ",
        {:cycle, [values: [1, 2]]},
        " ",
        {:cycle, [values: [1, 2]]},
        " ",
        {:cycle, [values: [1, 2, 3]]},
        " ",
        {:cycle, [values: [1, 2, 3]]},
        " ",
        {:cycle, [values: [1, 2, 3]]},
        " ",
        {:cycle, [values: [1, 2, 3]]}
      ]
    )
  end

  test "cycle tag group by numbers" do
    test_parse(
      "{%cycle 1: \"one\", \"two\" %} {%cycle 2: \"one\", \"two\" %} {%cycle 1: \"one\", \"two\" %} {%cycle 2: \"one\", \"two\" %} {%cycle 1: \"one\", \"two\" %} {%cycle 2: \"one\", \"two\" %}",
      [
        {:cycle, [group: ["1"], values: ["one", "two"]]},
        " ",
        {:cycle, [group: ["2"], values: ["one", "two"]]},
        " ",
        {:cycle, [group: ["1"], values: ["one", "two"]]},
        " ",
        {:cycle, [group: ["2"], values: ["one", "two"]]},
        " ",
        {:cycle, [group: ["1"], values: ["one", "two"]]},
        " ",
        {:cycle, [group: ["2"], values: ["one", "two"]]}
      ]
    )
  end

  test "cycle tag group by strings" do
    test_parse(
      "{%cycle var1: \"one\", \"two\" %} {%cycle var2: \"one\", \"two\" %} {%cycle var1: \"one\", \"two\" %} {%cycle var2: \"one\", \"two\" %} {%cycle var1: \"one\", \"two\" %} {%cycle var2: \"one\", \"two\" %}",
      [
        {:cycle, [group: ["var1"], values: ["one", "two"]]},
        " ",
        {:cycle, [group: ["var2"], values: ["one", "two"]]},
        " ",
        {:cycle, [group: ["var1"], values: ["one", "two"]]},
        " ",
        {:cycle, [group: ["var2"], values: ["one", "two"]]},
        " ",
        {:cycle, [group: ["var1"], values: ["one", "two"]]},
        " ",
        {:cycle, [group: ["var2"], values: ["one", "two"]]}
      ]
    )
  end
end
