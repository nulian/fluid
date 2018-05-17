defmodule Liquid.Combinators.Tags.CycleTest do
  use ExUnit.Case

  import Liquid.Helpers
  alias Liquid.NimbleParser, as: Parser

  test "cycle tag with 2 values" do
    test_combinator("{%cycle \"one\", \"two\"%}", &Parser.cycle/1, [
      {:cycle, ["\"one\"", "\"two\""]},
      ""
    ])
  end

  test "cycle tag 2 times" do
    test_combinator("{%cycle \"one\", \"two\"%} {%cycle \"one\", \"two\"%}", &Parser.cycle/1, [
      {:cycle, ["\"one\"", "\"two\""]},
      " ",
      {:cycle, ["\"one\"", "\"two\""]},
      ""
    ])
  end

  test "cycle tag with quoted blanks" do
    test_combinator("{%cycle \"\", \"two\"%} {%cycle \"\", \"two\"%}", &Parser.cycle/1, [
      {:cycle, ["\"\"", "\"two\""]},
      " ",
      {:cycle, ["\"\"", "\"two\""]},
      ""
    ])
  end

  test "cycle tag 3 times" do
    test_combinator(
      "{%cycle \"one\", \"two\"%} {%cycle \"one\", \"two\"%} {%cycle \"one\", \"two\"%}",
      &Parser.cycle/1,
      [
        {:cycle, ["\"one\"", "\"two\""]},
        " ",
        {:cycle, ["\"one\"", "\"two\""]},
        " ",
        {:cycle, ["\"one\"", "\"two\""]},
        ""
      ]
    )
  end

  test "cycle with html values" do
    test_combinator(
      "{%cycle \"text-align: left\", \"text-align: right\" %} {%cycle \"text-align: left\", \"text-align: right\"%}",
      &Parser.cycle/1,
      [
        {:cycle, ["\"text-align: left\"", "\"text-align: right\""]},
        " ",
        {:cycle, ["\"text-align: left\"", "\"text-align: right\""]},
        ""
      ]
    )
  end

  test "cycle tag with integers" do
    test_combinator(
      "{%cycle 1,2%} {%cycle 1,2%} {%cycle 1,2%} {%cycle 1,2,3%} {%cycle 1,2,3%} {%cycle 1,2,3%} {%cycle 1,2,3%}",
      &Parser.cycle/1,
      [
        {:cycle, [<<1>>, <<2>>]},
        " ",
        {:cycle, [<<1>>, <<2>>]},
        " ",
        {:cycle, [<<1>>, <<2>>]},
        " ",
        {:cycle, [<<1>>, <<2>>, <<3>>]},
        " ",
        {:cycle, [<<1>>, <<2>>, <<3>>]},
        " ",
        {:cycle, [<<1>>, <<2>>, <<3>>]},
        " ",
        {:cycle, [<<1>>, <<2>>, <<3>>]},
        ""
      ]
    )
  end

  test "cycle tag group by numbers" do
    test_combinator(
      "{%cycle 1: \"one\", \"two\" %} {%cycle 2: \"one\", \"two\" %} {%cycle 1: \"one\", \"two\" %} {%cycle 2: \"one\", \"two\" %} {%cycle 1: \"one\", \"two\" %} {%cycle 2: \"one\", \"two\" %}",
      &Parser.cycle/1,
      [
        {:cycle, ["1", "\"one\"", "\"two\""]},
        " ",
        {:cycle, ["2", "\"one\"", "\"two\""]},
        " ",
        {:cycle, ["1", "\"one\"", "\"two\""]},
        " ",
        {:cycle, ["2", "\"one\"", "\"two\""]},
        " ",
        {:cycle, ["1", "\"one\"", "\"two\""]},
        " ",
        {:cycle, ["2", "\"one\"", "\"two\""]},
        ""
      ]
    )
  end

  test "cycle tag group by strings" do
    test_combinator(
      "{%cycle var1: \"one\", \"two\" %} {%cycle var2: \"one\", \"two\" %} {%cycle var1: \"one\", \"two\" %} {%cycle var2: \"one\", \"two\" %} {%cycle var1: \"one\", \"two\" %} {%cycle var2: \"one\", \"two\" %}",
      &Parser.cycle/1,
      [
        {:cycle, ["var1", "\"one\"", "\"two\""]},
        " ",
        {:cycle, ["var2", "\"one\"", "\"two\""]},
        " ",
        {:cycle, ["var1", "\"one\"", "\"two\""]},
        " ",
        {:cycle, ["var2", "\"one\"", "\"two\""]},
        " ",
        {:cycle, ["var1", "\"one\"", "\"two\""]},
        " ",
        {:cycle, ["var2", "\"one\"", "\"two\""]},
        ""
      ]
    )
  end

  test "cycle tag without coma" do
    test_combinator_error("{%cycle 1 2 %}", &Parser.cycle/1)
  end
end
