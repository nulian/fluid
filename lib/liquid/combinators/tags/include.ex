defmodule Liquid.Combinators.Tags.Include do
  @moduledoc """
  Include allows templates to relate with other templates
  """
  import NimbleParsec
  alias Liquid.Combinators.General

  def snippet_var do
    parsec(:ignore_whitespaces)
    |> concat(utf8_char([General.codepoints().apostrophe]))
    |> ascii_char([General.codepoints().underscore, ?A..?Z, ?a..?z])
    |> optional(
      repeat(
        ascii_char([
          General.codepoints().point,
          General.codepoints().underscore,
          General.codepoints().question_mark,
          General.codepoints().digit,
          General.codepoints().uppercase_letter,
          General.codepoints().lowercase_letter
        ])
      )
    )
    |> ascii_char([General.codepoints().apostrophe])
    |> parsec(:ignore_whitespaces)
    |> reduce({List, :to_string, []})
    |> tag(:snippet)
  end

  def variable_atom do
    empty()
    |> parsec(:ignore_whitespaces)
    |> ascii_char([General.codepoints().underscore, ?A..?Z, ?a..?z])
    |> optional(
      repeat(
        ascii_char([
          General.codepoints().point,
          General.codepoints().underscore,
          General.codepoints().question_mark,
          General.codepoints().digit,
          General.codepoints().uppercase_letter,
          General.codepoints().lowercase_letter
        ])
      )
    )
    |> concat(ascii_char([General.codepoints().colon]))
    |> parsec(:ignore_whitespaces)
    |> reduce({List, :to_string, []})
    |> tag(:variable_atom)
  end

  def var_assignation do
    General.cleaned_comma()
    |> concat(parsec(:variable_atom))
    |> concat(parsec(:ignore_whitespaces))
    |> concat(parsec(:snippet_var))
    |> parsec(:ignore_whitespaces)
    |> optional(parsec(:var_assignation))
  end

  #   # {% include 'color' with 'red' %}
  def with_param do
    empty()
    |> ignore(string("with"))
    |> concat(parsec(:ignore_whitespaces))
    |> concat(parsec(:snippet_var))
    |> concat(parsec(:ignore_whitespaces))
    |> tag(:with_param)
  end

  # {% include 'color' for 'red' %}
  def for_param do
    empty()
    |> ignore(string("for"))
    |> concat(parsec(:ignore_whitespaces))
    |> concat(parsec(:snippet_var))
    |> concat(parsec(:ignore_whitespaces))
    |> tag(:for_param)
  end

  def tag do
    empty()
    |> parsec(:start_tag)
    |> ignore(string("include"))
    |> concat(parsec(:ignore_whitespaces))
    |> concat(parsec(:snippet_var))
    |> concat(parsec(:ignore_whitespaces))
    |> optional(choice([parsec(:with_param), parsec(:for_param), parsec(:var_assignation)]))
    |> concat(parsec(:end_tag))
    |> tag(:include)
    |> optional(parsec(:__parse__))
  end
end
