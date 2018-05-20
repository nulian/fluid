defmodule Liquid.Combinators.Tags.For do
  @moduledoc """
  "for" tag iterates over an array or collection.
  Several useful variables are available to you within the loop.

  Basic usage:
  ```
    {% for item in collection %}
      {{ forloop.index }}: {{ item.name }}
    {% endfor %}
  ```
  Advanced usage:
  ```
    {% for item in collection %}
      <div {% if forloop.first %}class="first"{% endif %}>
      Item {{ forloop.index }}: {{ item.name }}
      </div>
    {% else %}
      There is nothing in the collection.
    {% endfor %}
  ```
  You can also define a limit and offset much like SQL.  Remember
  that offset starts at 0 for the first item.
  ```
    {% for item in collection limit:5 offset:10 %}
      {{ item.name }}
    {% end %}
  ```
  To reverse the for loop simply use {% for item in collection reversed %}

  Available variables:
  ```
    forloop.name:: 'item-collection'
    forloop.length:: Length of the loop
    forloop.index:: The current item's position in the collection;
    forloop.index starts at 1.
    This is helpful for non-programmers who start believe
    the first item in an array is 1, not 0.
    forloop.index0:: The current item's position in the collection
    where the first item is 0
    forloop.rindex:: Number of items remaining in the loop
    (length - index) where 1 is the last item.
    forloop.rindex0:: Number of items remaining in the loop
    where 0 is the last item.
    forloop.first:: Returns true if the item is the first item.
    forloop.last:: Returns true if the item is the last item.
    forloop.parentloop:: Provides access to the parent loop, if present.
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
    |> concat(choice([parsec(:number), parsec(:variable_definition)]))
    |> parsec(:ignore_whitespaces)
    |> tag(:offset_param)
  end

  @doc "For limit param: {% for products in products limit:2 %}"
  def limit_param do
    empty()
    |> parsec(:ignore_whitespaces)
    |> ignore(string("limit"))
    |> ignore(ascii_char([General.codepoints().colon]))
    |> parsec(:ignore_whitespaces)
    |> concat(choice([parsec(:number), parsec(:variable_definition)]))
    |> parsec(:ignore_whitespaces)
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
    |> optional(
      times(
        choice([parsec(:offset_param), parsec(:reversed_param), parsec(:limit_param)]),
        min: 1
      )
    )
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
