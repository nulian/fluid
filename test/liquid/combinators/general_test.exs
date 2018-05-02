defmodule Liquid.Combinators.GeneralTest do
  use ExUnit.Case
  import Liquid.Helpers

  alias Liquid.NimbleParser, as: Parser

  test "whitespace must parse 0x0020 and 0x0009" do
    test_combiner(" ", &Parser.whitespace/1, ' ')
    test_combiner("\t", &Parser.whitespace/1, '\t')
  end

  test "literal: every utf8 valid character until open/close tag/variable" do
    test_combiner(
      "Chinese: 你好, English: Whatever, Arabian: مرحبا",
      &Parser.literal/1,
      literal: ["Chinese: 你好, English: Whatever, Arabian: مرحبا"]
    )

    test_combiner("stop in {{", &Parser.literal/1, literal: ["stop in "])
    test_combiner("stop in {%", &Parser.literal/1, literal: ["stop in "])
    test_combiner("stop in %}", &Parser.literal/1, literal: ["stop in "])
    test_combiner("stop in }}", &Parser.literal/1, literal: ["stop in "])
    test_combiner("{{ this is not processed", &Parser.literal/1, literal: [""])
    test_combiner("", &Parser.literal/1, literal: [""])
  end

  # test "name: /[_A-Za-z][.][_0-9A-Za-z][?]*/" do
  #   test_combiner("  \t _variable   \t   ", &Parser.name/1, [{:name, ["_variable"]}])
  #   test_combiner("cart.product.name?", &Parser.name/1, [{:name, ["cart.product.name?"]}])
  # end

  test "extra_spaces ignore all :whitespaces" do
    test_combiner("      ", &Parser.ignore_whitespaces/1, [])
    test_combiner("    \t\t\t  ", &Parser.ignore_whitespaces/1, [])
    test_combiner("", &Parser.ignore_whitespaces/1, [])
  end

  test "start_tag" do
    test_combiner("{%", &Parser.start_tag/1, [])
    test_combiner("{%   \t   \t", &Parser.start_tag/1, [])
  end

  test "end_tag" do
    test_combiner("%}", &Parser.end_tag/1, [])
    test_combiner("   \t   \t%}", &Parser.end_tag/1, [])
  end

  test "start_var" do
    test_combiner("{{", &Parser.start_var/1, [])
    test_combiner("{{   \t   \t", &Parser.start_var/1, [])
  end

  test "end_var" do
    test_combiner("}}", &Parser.end_var/1, [])
    test_combiner("   \t   \t}}", &Parser.end_var/1, [])
  end
end
