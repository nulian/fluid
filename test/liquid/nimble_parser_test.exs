defmodule Liquid.NimbleParserTest do
  use ExUnit.Case
  import Liquid.Helpers

  alias Liquid.NimbleParser, as: Parser

  test "integer value" do
    test_combinator("5", &Parser.value/1, [5])
    test_combinator("-5", &Parser.value/1, [-5])
    test_combinator("0", &Parser.value/1, [0])
  end

  test "float value" do
    test_combinator("3.14", &Parser.value/1, [3.14])
    test_combinator("-3.14", &Parser.value/1, [-3.14])
    test_combinator("1.0E5", &Parser.value/1, [1.0e5])
    test_combinator("1.0e5", &Parser.value/1, [1.0e5])
    test_combinator("-1.0e5", &Parser.value/1, [-1.0e5])
    test_combinator("1.0e-5", &Parser.value/1, [1.0e-5])
    test_combinator("-1.0e-5", &Parser.value/1, [-1.0e-5])
  end

  test "string value" do
    test_combinator(~S("abc"), &Parser.value/1, ["abc"])
    test_combinator(~S(""), &Parser.value/1, [""])
  end

  #   - BooleanValue
  #   - NullValue
  #   - ListValue[?Const]

  test "boolean values" do
    test_combinator("true", &Parser.value/1, ["true"])
    test_combinator("false", &Parser.value/1, ["false"])
  end
end
