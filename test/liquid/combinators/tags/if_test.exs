defmodule Liquid.Combinator.Tags.IfTest do
  use ExUnit.Case

  import Liquid.Helpers
  alias Liquid.NimbleParser, as: Parser

  test "opening if tag with one condition " do
    test_combinator("{%  if product.title == 'Awesome Shoes' %}", &Parser.if/1, [
      {},
      ""
    ])
  end

  test "opening if tag with multiple conditions " do
    test_combinator("{% if line_item.grams > 20000 and customer_address.city == 'Ottawa' or customer_address.city == 'Seatle' %}", &Parser.if/1, [
      {},
      ""
    ])
  end

end
