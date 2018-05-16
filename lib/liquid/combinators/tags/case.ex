defmodule Liquid.Combinators.Tags.Case do
  import NimbleParsec

  def open_tag do
    empty()
    |> parsec(:start_tag)
    |> ignore(string("case"))
    |> concat(parsec(:ignore_whitespaces))
    |> choice([
      parsec(:value_definition),
      parsec(:token),
      parsec(:variable_definition)
    ])
    |> concat(parsec(:end_tag))
  end

  def when_tag do
    empty()
    |> concat(parsec(:start_tag))
    |> ignore(string("when"))
    |> concat(parsec(:ignore_whitespaces))
    |> choice([
      parsec(:value_definition),
      parsec(:token),
      parsec(:variable_definition)
    ])
    |> optional(
      times(choice([parsec(:or_contition_value), parsec(:comma_contition_value)]), min: 1)
    )
    |> parsec(:end_tag)
    |> parsec(:output_text)
    |> tag(:when)
  end

  def close_tag do
    parsec(:start_tag)
    |> ignore(string("endcase"))
    |> concat(parsec(:end_tag))
  end

  def tag do
    parsec(:open_tag_case)
    |> concat(times(parsec(:when_tag), min: 1))
    |> concat(parsec(:ignore_whitespaces))
    |> concat(optional(parsec(:else_tag)))
    |> concat(parsec(:close_tag_case))
    |> tag(:case)
  end

  # {% case condition %}{% when 1 or 2 or 3 %} its 1 or 2 or 3 {% when 4 %} its 4 {% endcase %}
end
