defmodule Liquid.Combinators.GeneralTest do
  use ExUnit.Case

  defmodule Parser do
    import NimbleParsec
    alias Liquid.Combinators.General

    defparsec(:whitespace, General.whitespace())
    defparsec(:literal, General.literal())
    defparsec(:ignore_whitespaces, General.ignore_whitespaces())
  end

  test "whitespace must parse 0x0020 and 0x0009" do
    test_combiner(" ", &Parser.whitespace/1, ' ')
  end

  test "literal: every utf8 valid character" do
    test_combiner("Chinese: 你好, English: Whatever, Arabian: مرحبا",
      &Parser.literal/1,
      [literal: ["Chinese: 你好, English: Whatever, Arabian: مرحبا"]]
    )
  end

  test "extra_spaces ignore all :whitespaces" do
    test_combiner("      ", &Parser.ignore_whitespaces/1, [])
    test_combiner("    \t\t\t  ", &Parser.ignore_whitespaces/1, [])
  end

  defp test_combiner(markdown, combiner, expected) do
    {:ok, response, _, _, _, _} = combiner.(markdown)
    assert response == expected
  end
end
