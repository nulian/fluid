defmodule Liquid.Combinators.Tags.Cycle do
  alias Liquid.Combinators.General
  import NimbleParsec

  alias Liquid.Template

  def cycle_group do
    # |> ignore())
    parsec(:ignore_whitespaces)
    |> concat(
      choice([
        parsec(:token),
        repeat(utf8_char(not: ?,, not: ?:))
      ])
    )
    |> concat(utf8_char([?:]))
    |> reduce({List, :to_string, []})
  end

  def last_cycle_value do
    parsec(:ignore_whitespaces)
    |> choice([
      parsec(:token),
      parsec(:number_in_string)
    ])
    |> concat(parsec(:end_tag))
    |> reduce({List, :to_string, []})
  end

  def cycle_values do
    empty()
    |> choice([
      parsec(:token),
      parsec(:number_in_string)
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

  ##################### render ###################

  # [{:cycle, ["\"one\"", "\"two\""]}, " ", {:cycle, ["\"one\"", "\"two\""]}]
  # [["\"one\"", "\"two\""], " ", ["\"one\"", "\"two\""]]

  # %Liquid.Tag{
  #         attributes: [],
  #         blank: false,
  #         markup: "\"one\", \"two\"",
  #         name: :cycle,
  #         parts: ["\"one\", \"two\"", "\"one\"", "\"two\""]
  #       }

  def transformation({:ok, list}) do
    trans =
      Enum.filter(list, fn x -> x != "" end)
      |> Enum.map(&create(&1))

    block = %Liquid.Block{name: :document, nodelist: trans}
    %Template{root: block}
  end

  def create({:cycle, markup}) do
    value = Enum.join(markup, ", ")
    {name, values} = Liquid.Cycle.get_name_and_values(value)
    %Liquid.Tag{name: :cycle, markup: value, parts: [name | values]}
  end

  def create(any) do
    any
  end
end
