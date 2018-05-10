defmodule Liquid.Combinators.Tags.Cycle do
  alias Liquid.Combinators.General
  import NimbleParsec

  def cycle_group do
    parsec(:ignore_whitespaces)
    |> concat(
      choice([
        parsec(:token),
        repeat(utf8_char(not: ?,, not: ?:))
      ])
    )
    |> reduce({List, :to_string, []})
    |> concat(utf8_char([?:]) |> ignore())
  end

  def last_cycle_value do
    parsec(:ignore_whitespaces)
    |> choice([
      parsec(:token),
      parsec(:number)
    ])
    |> concat(parsec(:end_tag))
    |> reduce({List, :to_string, []})
  end

  def cycle_values do
    empty()
    |> choice([
      parsec(:token),
      parsec(:number)
    ])
    |> concat(parsec(:ignore_whitespaces))
    |> concat(utf8_char([General.codepoints().comma]) |> ignore())
    |> reduce({List, :to_string, []})
    |> choice([parsec(:cycle_values), parsec(:last_cycle_value)])
  end

  def tag do
    empty()
    |> parsec(:start_tag)
    |> concat(string("cycle") |> ignore())
    |> concat(optional(parsec(:cycle_group)))
    |> concat(parsec(:ignore_whitespaces))
    |> concat(choice([parsec(:cycle_values), parsec(:last_cycle_value)]))
    |> tag(:cycle)
    |> optional(parsec(:__parse__))
  end
end
