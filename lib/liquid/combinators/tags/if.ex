defmodule Liquid.Combinators.Tags.If do
  import NimbleParsec
  alias Liquid.Combinators.General

  @doc "Open if tag: {% if variable ==  value %}"

  def open_tag do
    empty()
    |> parsec(:start_tag)
    |> ignore(string("if"))
    |> concat(parsec(:ignore_whitespaces))
    |> choice([
      parsec(:conditions),
      parsec(:boolean_value),
      parsec(:token)
    ])
    |> optional(
      times(choice([parsec(:logical_conditions), parsec(:logical_conditions_wo_math)]), min: 1)
    )
    |> concat(parsec(:end_tag))
    |> concat(parsec(:output_text))
  end

  def conditions do
    parsec(:ignore_whitespaces)
    |> concat(parsec(:value_definition))
    |> concat(parsec(:ignore_whitespaces))
    |> concat(parsec(:math_operators))
    |> concat(parsec(:ignore_whitespaces))
    |> concat(parsec(:value_definition))
    |> concat(parsec(:ignore_whitespaces))
    |> tag(:condition)
  end

  def logical_conditions do
    parsec(:logical_operators)
    |> concat(parsec(:conditions))
  end

  def logical_conditions_wo_math do
    parsec(:logical_operators)
    |> concat(parsec(:variable_name))
  end

  def elsif_tag do
    empty()
    |> parsec(:start_tag)
    |> ignore(string("elsif"))
    |> concat(parsec(:ignore_whitespaces))
    |> choice([
      parsec(:conditions),
      parsec(:boolean_value),
      parsec(:token)
    ])
    |> optional(
      times(choice([parsec(:logical_conditions), parsec(:logical_conditions_wo_math)]), min: 1)
    )
    |> concat(parsec(:end_tag))
    |> concat(parsec(:output_text))
    |> tag(:elsif)
  end

  def else_tag do
    parsec(:ignore_whitespaces)
    |> concat(parsec(:start_tag))
    |> ignore(string("else"))
    |> concat(parsec(:end_tag))
    |> parsec(:output_text)
    |> tag(:else)
  end

  @doc "Close if tag: {% endif %}"
  def close_tag do
    parsec(:start_tag)
    |> ignore(string("endif"))
    |> concat(parsec(:end_tag))
  end

  def output_text do
    repeat_until(utf8_char([]), [string(General.codepoints().start_tag)])
    |> reduce({List, :to_string, []})
    |> tag(:output_text)
  end

  def if_content do
    empty()
    |> optional(
      times(
        choice([
          parsec(:elsif_tag),
          parsec(:if),
          parsec(:unless)
        ]),
        min: 1
      )
    )
    |> optional(times(parsec(:else_tag), min: 1))
  end

  def tag do
    empty()
    |> parsec(:open_tag_if)
    |> concat(parsec(:if_content))
    |> parsec(:close_tag_if)
    |> tag(:if)
    |> optional(parsec(:__parse__))
  end
end
