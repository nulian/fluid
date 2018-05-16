defmodule Liquid.Combinator.Tags.CaseTest do
  use ExUnit.Case

  import Liquid.Helpers
  alias Liquid.NimbleParser, as: Parser

  test "case using multiples when" do
    test_combinator(
      "{% case condition %}{% when 1 %} its 1 {% when 2 %} its 2 {% endcase %}",
      &Parser.case/1,
      case: [
        "condition",
        {:when, [1, {:output_text, [" its 1 "]}]},
        {:when, [2, {:output_text, [" its 2 "]}]}
      ]
    )
  end

  test "case using a single when" do
    test_combinator(
      "{% case condition %}{% when \"string here\" %} hit {% endcase %}",
      &Parser.case/1,
      case: [
        "condition",
        {:when, ["string here", {:output_text, [" hit "]}]}
      ]
    )
  end

  test "evaluate variables and expressions" do
    test_combinator(
      "{% case a.size %}{% when 1 %}1{% when 2 %}2{% endcase %}",
      &Parser.case/1,
      case: [
        "a.size",
        {:when, [1, {:output_text, ["1"]}]},
        {:when, [2, {:output_text, ["2"]}]}
      ]
    )
  end

  test "case with a else tag" do
    test_combinator(
      "{% case condition %}{% when 5 %} hit {% else %} else {% endcase %}",
      &Parser.case/1,
      case: [
        "condition",
        {:when, [5, {:output_text, [" hit "]}]},
        {:else, [output_text: [" else "]]}
      ]
    )
  end
end
