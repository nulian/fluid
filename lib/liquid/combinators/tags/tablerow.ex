defmodule Liquid.Combinators.Tags.Tablerow do
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

  @doc "Tablerow offset param: {% tablerow products in products cols:2 %}"
  def cols_param do
    empty()
    |> parsec(:ignore_whitespaces)
    |> ignore(string("cols"))
    |> ignore(ascii_char([General.codepoints().colon]))
    |> parsec(:ignore_whitespaces)
    |> concat(parsec(:number))
    |> parsec(:ignore_whitespaces)
    |> tag(:cols_param)
  end

  def tablerow_sentences do
    empty()
    |> optional(parsec(:__parse__))
    |> tag(:tablerow_sentences)
  end

  @doc "Open Tablerow tag: {% tablerow products in products %}"
  def open_tag do
    empty()
    |> parsec(:start_tag)
    |> ignore(string("tablerow"))
    |> parsec(:variable_name)
    |> parsec(:ignore_whitespaces)
    |> ignore(string("in"))
    |> parsec(:ignore_whitespaces)
    |> choice([parsec(:range_value), parsec(:value)])
    |> optional(choice([parsec(:offset_param), parsec(:cols_param), parsec(:limit_param)]))
    |> parsec(:ignore_whitespaces)
    |> concat(parsec(:end_tag))
    |> tag(:tablerow_conditions)
    |> parsec(:tablerow_sentences)
  end

  @doc "Close Tablerow tag: {% endtablerow %}"
  def close_tag do
    empty()
    |> parsec(:start_tag)
    |> ignore(string("endtablerow"))
    |> concat(parsec(:end_tag))
  end

  def tag do
    empty()
    |> parsec(:open_tag_tablerow)
    |> parsec(:close_tag_tablerow)
    |> tag(:tablerow)
    |> optional(parsec(:__parse__))
  end
end
