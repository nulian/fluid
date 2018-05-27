defmodule Liquid.Combinators.Tags.If do
  @moduledoc """
  Executes a block of code only if a certain condition is true.
  If this condition is false executes `else` block of code
  Input:
  ```
  {% if product.title == 'Awesome Shoes' %}
    These shoes are awesome!
  {% else %}
    These shoes are ugly!
  {% endif %}
  ```
  Output:
  ```
    These shoes are ugly!
  ```
  """

  import NimbleParsec
  alias Liquid.Combinators.General

  defp open_tag do
    empty()
    |> parsec(:start_tag)
    |> ignore(string("if"))
    |> concat(parsec(:ignore_whitespaces))
    |> choice([
        parsec(:condition),
        parsec(:variable_definition),
        parsec(:value_definition),
        parsec(:quoted_token)
      ])
    |> optional(times(parsec(:logical_condition), min: 1))
    |> concat(parsec(:end_tag))
    |> optional(parsec(:__parse__))
  end

  def condition do
    parsec(:ignore_whitespaces)
    |> concat(parsec(:value_definition))
    |> concat(parsec(:comparison_operators))
    |> concat(parsec(:value_definition))
    |> parsec(:ignore_whitespaces)
    |> tag(:condition)
  end

  def logical_condition do
    parsec(:logical_operators)
    |> concat(choice([parsec(:condition), parsec(:variable_name), parsec(:value_definition)]))
  end

  def elsif_tag do
    empty()
    |> parsec(:start_tag)
    |> ignore(string("elsif"))
    |> concat(parsec(:ignore_whitespaces))
    |> choice([
      parsec(:condition),
      parsec(:variable_definition),
      parsec(:value_definition),
      parsec(:quoted_token)
    ])
    |> optional(times(parsec(:logical_condition), min: 1))
    |> concat(parsec(:end_tag))
    |> optional(parsec(:__parse__))
    |> tag(:elsif)
  end

  def else_tag do
    parsec(:ignore_whitespaces)
    |> concat(parsec(:start_tag))
    |> ignore(string("else"))
    |> concat(parsec(:end_tag))
    |> parsec(:ignore_whitespaces)
    |> optional(parsec(:__parse__))
    |> tag(:else)
  end

  defp close_tag do
    parsec(:start_tag)
    |> ignore(string("endif"))
    |> concat(parsec(:end_tag))
  end

  def output_text do
    repeat_until(utf8_char([]), [
      string(General.codepoints().start_tag),
      string(General.codepoints().start_variable)
    ])
    |> reduce({List, :to_string, []})
    |> tag(:output_text)
  end

  def if_content do
    empty()
    |> optional(parsec(:__parse__))
    |> tag(:if_sentences)
  end

  def tag do
    open_tag()
    |> optional(times(parsec(:elsif_tag), min: 1))
    |> optional(times(parsec(:else_tag), min: 1))
    |> concat(close_tag())
    |> tag(:if)
    |> optional(parsec(:__parse__))
  end
end
# 111
