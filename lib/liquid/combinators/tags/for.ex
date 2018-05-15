defmodule Liquid.Combinators.Tags.For do
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

  @doc "For offset param: {% for products in products offset:2 %}"
  def offset_param do
    empty()
    |> parsec(:ignore_whitespaces)
    |> ignore(string("offset"))
    |> ignore(ascii_char([General.codepoints().colon]))
    |> parsec(:ignore_whitespaces)
    |> concat(parsec(:number))
    |> parsec(:ignore_whitespaces)
    #|> reduce({List, :to_string, []})
    |> tag(:offset_param)
  end

  @doc "For limit param: {% for products in products limit:2 %}"
  def limit_param do
    empty()
    |> parsec(:ignore_whitespaces)
    |> ignore(string("limit"))
    |> ignore(ascii_char([General.codepoints().colon]))
    |> parsec(:ignore_whitespaces)
    |> concat(parsec(:number))
    |> parsec(:ignore_whitespaces)
    #|> reduce({List, :to_integer, []})
    |> tag(:limit_param)
  end

  @doc "For reversed param: {% for products in products reversed %}"
  def reversed_param do
    empty()
    |> parsec(:ignore_whitespaces)
    |> ignore(string("reversed"))
    |> parsec(:ignore_whitespaces)
    |> tag(:reversed_param)
  end

  def for_sentences do
    empty()
    |> optional(parsec(:__parse__))
    |> tag(:for_sentences)
   end

  @doc "Open For tag: {% for products in products %}"
  def open_tag do
    empty()
    |> parsec(:start_tag)
    |> ignore(string("for"))
    |> parsec(:variable_name)
    |> parsec(:ignore_whitespaces)
    |> ignore(string("in"))
    |> parsec(:ignore_whitespaces)
    |> choice([parsec(:range_value), parsec(:value)])
    |> optional(choice([parsec(:offset_param), parsec(:reversed_param), parsec(:limit_param)]))
    |> parsec(:ignore_whitespaces)
    |> concat(parsec(:end_tag))
    |> tag(:for_conditions)
    |> parsec(:for_sentences)
  end

  @doc "Close For tag: {% endfor %}"
  def close_tag do
    empty()
    |> parsec(:start_tag)
    |> ignore(string("endfor"))
    |> concat(parsec(:end_tag))
  end

  @doc "For Else tag: {% else %}"
  def else_tag do
    empty()
    |> parsec(:start_tag)
    |> ignore(string("else"))
    |> concat(parsec(:end_tag))
    |> optional(parsec(:__parse__))
    |> tag(:else_sentences)

  end

  @doc "For Break tag: {% break %}"
  def break_tag do
    empty()
    |> parsec(:start_tag)
    |> ignore(string("break"))
    |> concat(parsec(:end_tag))
    |> tag(:break)
    |> optional(parsec(:__parse__))
  end

  @doc "For Continue tag: {% continue %}"
  def continue_tag do
    empty()
    |> parsec(:start_tag)
    |> ignore(string("continue"))
    |> concat(parsec(:end_tag))
    |> tag(:continue)
    |> optional(parsec(:__parse__))
  end

  def tag do
    empty()
    |> parsec(:open_tag_for)
    |> optional(parsec(:else_tag_for))
    |> parsec(:close_tag_for)
    |> tag(:for)
    |> optional(parsec(:__parse__))
  end
end
