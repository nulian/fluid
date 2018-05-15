defmodule Liquid.Combinators.Tags.If do
  @moduledoc """
  Allows you to leave un-rendered code inside a Liquid template.
  Any text within the opening and closing comment blocks will not be output,
  and any Liquid code within will not be executed
  Input:
  ```
    Anything you put between {% comment %} and {% endcomment %} tags
    is turned into a comment.
  ```
  Output:
  ```
    Anything you put between  tags
    is turned into a comment
  ```
  """
  import NimbleParsec
  alias Liquid.Combinators.General

  @doc "Open if tag: {% if variable ==  value %}"
  def open_tag do
    empty()
    |> parsec(:start_tag)
    |> ignore(string("if"))
    |> concat(parsec(:ignore_whitespaces))
    |> times(
      choice([
        parsec(:conditions),
        parsec(:logical_conditions),
        parsec(:boolean_value),
        parsec(:token),
        parsec(:logical_conditions_wo_math)
      ]),
      min: 1
    )
    |> concat(parsec(:end_tag))
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
    |> times(
      choice([parsec(:conditions), parsec(:logical_conditions), parsec(:boolean_value)]),
      min: 1
    )
    |> concat(parsec(:end_tag))
    |> tag(:elsif)
  end

  def else_tag do
    # |> repeat_until(utf8_char([]), [string(General.codepoints().start_tag)])
    # |> reduce({List, :to_string, []})
    parsec(:ignore_whitespaces)
    |> concat(parsec(:start_tag))
    |> ignore(string("else"))
    |> concat(parsec(:end_tag))
    |> repeat_until(utf8_char([]), [string(General.codepoints().start_tag)])
    |> tag(:else)

    # |> repeat_until(utf8_char([]), [string(General.codepoints().start_tag)])
  end

  @doc "Close if tag: {% endif %}"
  def close_tag do
    parsec(:start_tag)
    |> ignore(string("endif"))
    |> concat(parsec(:end_tag))
  end

  def not_close_tag_if do
    empty()
    |> ignore(utf8_char([]))
    |> parsec(:if_content)
  end

  def if_content do
    empty()
    |> repeat_until(utf8_char([]), [string(General.codepoints().start_tag)])
    |> reduce({List, :to_string, []})
    |> times(
      choice([
        parsec(:elsif_tag),
        parsec(:else_tag),
        parsec(:close_tag_if),
        parsec(:if),
        parsec(:not_close_tag_if)
      ]),
      min: 1
    )
  end

  def tag do
    empty()
    |> parsec(:open_tag_if)
    |> concat(parsec(:if_content))
    |> tag(:if)
    |> optional(parsec(:__parse__))
  end
end
