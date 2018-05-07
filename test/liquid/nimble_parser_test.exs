defmodule Liquid.NimbleParserTest do
  use ExUnit.Case
  import Liquid.Helpers

  alias Liquid.NimbleParser, as: Parser

  test "integer value" do
    test_combinator("5", &Parser.value/1, value: 5)
    test_combinator("-5", &Parser.value/1, value: -5)
    test_combinator("0", &Parser.value/1, value: 0)
  end

  test "float value" do
    test_combinator("3.14", &Parser.value/1, value: 3.14)
    test_combinator("-3.14", &Parser.value/1, value: -3.14)
    test_combinator("1.0E5", &Parser.value/1, value: 1.0e5)
    test_combinator("1.0e5", &Parser.value/1, value: 1.0e5)
    test_combinator("-1.0e5", &Parser.value/1, value: -1.0e5)
    test_combinator("1.0e-5", &Parser.value/1, value: 1.0e-5)
    test_combinator("-1.0e-5", &Parser.value/1, value: -1.0e-5)
  end

  test "string value" do
    test_combinator(~S("abc"), &Parser.value/1, value: "abc")
    test_combinator(~S(""), &Parser.value/1, value: "")
    test_combinator(~S("mom's chicken"), &Parser.value/1, value: "mom's chicken")
    test_combinator(~S("這是傳統的中文"), &Parser.value/1, value: "這是傳統的中文")
    test_combinator(~S( "هذا باللغة العربية"), &Parser.value/1, value: "هذا باللغة العربية")
    test_combinator(~S("😁😂😃😉"), &Parser.value/1, value: "😁😂😃😉")
  end

  test "boolean values" do
    test_combinator("true", &Parser.value/1, value: "true")
    test_combinator("false", &Parser.value/1, value: "false")
  end
end
