defmodule Liquid.Combinators.Tags.Cycle do

alias Liquid.Combinators.General
import NimbleParsec

defparsec(:ignore_whitespaces, General.ignore_whitespaces())
defparsec(:start_tag, General.start_tag())
defparsec(:end_tag, General.end_tag())


  def single_quoted_string do
    parsec(:ignore_whitespaces)
    |> concat(utf8_char([General.codepoints().apostrophe]) |> ignore())
    |> concat(repeat(utf8_char(not: ?,, not: ?')))
    |> concat(parsec(:ignore_whitespaces))
    |> concat(utf8_char([General.codepoints().apostrophe]) |> ignore())
    |> concat(parsec(:ignore_whitespaces))
  end



  def double_quoted_string do
    parsec(:ignore_whitespaces)
    |> concat(ascii_char([?"]))
    |> concat(repeat(utf8_char(not: ?,, not: ?")))
    |> concat(ascii_char([?"]))
    |> reduce({List, :to_string, []})
    |> concat(parsec(:ignore_whitespaces))
  end



 def integer_value, do: integer(min: 1)



   def cycle_group do
    parsec(:ignore_whitespaces)
    |> concat(
      choice([
        parsec(:single_quoted_string),
        parsec(:double_quoted_string),
        repeat(utf8_char(not: ?,, not: ?:))
      ])
    )
    |> reduce({List, :to_string, []})
    |> concat(utf8_char([?:]) |> ignore()) end



   def last_cycle_value do
    parsec(:ignore_whitespaces)
    |> choice([
      parsec(:single_quoted_string),
      parsec(:double_quoted_string),
      parsec(:integer_value)
    ])
    |> concat(parsec(:end_tag))
    |> reduce({List, :to_string, []}) end



  def cycle_values do
    empty()
    |> choice([
      parsec(:single_quoted_string),
      parsec(:double_quoted_string),
      parsec(:integer_value)
    ])
    |> concat(parsec(:ignore_whitespaces))
    |> concat(utf8_char([General.codepoints().comma]) |> ignore())
    |> reduce({List, :to_string, []})
    |> choice([parsec(:cycle_values), parsec(:last_cycle_value)]) end



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
