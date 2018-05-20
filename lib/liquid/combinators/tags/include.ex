defmodule Liquid.Combinators.Tags.Include do
  @moduledoc """
  Include allows templates to relate with other templates
  """
  import NimbleParsec
  alias Liquid.Combinators.General

  def snippet do
    parsec(:ignore_whitespaces)
    |> concat(utf8_char([General.codepoints().single_quote]))
    |> parsec(:variable_definition)
    |> ascii_char([General.codepoints().single_quote])
    |> parsec(:ignore_whitespaces)
    |> reduce({List, :to_string, []})
    |> tag(:snippet)
  end

  def variable_atom do
    empty()
    |> parsec(:ignore_whitespaces)
    |> parsec(:variable_definition)
    |> concat(ascii_char([General.codepoints().colon]))
    |> parsec(:ignore_whitespaces)
    |> reduce({List, :to_string, []})
    |> tag(:variable_name)
  end

  def var_assignment do
    General.cleaned_comma()
    |> concat(parsec(:variable_atom))
    |> concat(parsec(:ignore_whitespaces))
    |> concat(parsec(:value))
    |> parsec(:ignore_whitespaces)
    |> tag(:variables)
    |> optional(parsec(:var_assignment))
  end

  #   # {% include 'color' with 'red' %}
  def with_param do
    empty()
    |> ignore(string("with"))
    |> concat(parsec(:ignore_whitespaces))
    |> concat(parsec(:value_definition))
    |> concat(parsec(:ignore_whitespaces))
    |> tag(:with_param)
  end

  # {% include 'color' for 'red' %}
  def for_param do
    empty()
    |> ignore(string("for"))
    |> concat(parsec(:ignore_whitespaces))
    |> concat(parsec(:value_definition))
    |> concat(parsec(:ignore_whitespaces))
    |> tag(:for_param)
  end

  def tag do
    empty()
    |> parsec(:start_tag)
    |> ignore(string("include"))
    |> concat(parsec(:ignore_whitespaces))
    |> concat(parsec(:snippet))
    |> concat(parsec(:ignore_whitespaces))
    |> optional(choice([parsec(:with_param), parsec(:for_param), parsec(:var_assignment)]))
    |> concat(parsec(:end_tag))
    |> tag(:include)
    |> optional(parsec(:__parse__))
  end
end
