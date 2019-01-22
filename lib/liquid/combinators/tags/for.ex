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
  alias Liquid.Combinators.{General, Tag, LexicalToken}
  alias Liquid.Combinators.Tags.Generic

  @type t :: [for: For.markup()]
  @type markup :: [
          statements: [
            variable: String.t(),
            value: LexicalToken.value(),
            params: [
              [offset: Integer.t() | String.t()]
              | [limit: Integer.t() | String.t()]
            ],
            body:
              Liquid.NimbleParser.t()
              | Generic.else_tag()
          ]
        ]

  @doc """
  Parses a `Liquid` Continue tag, this is used for a internal behavior of the `for` tag,
  creates a keyword list with a key `continue` and the value is an empty list.
  """
  @spec continue_tag() :: NimbleParsec.t()
  def continue_tag, do: Tag.define_open("continue")

  @doc """
  Parses a `Liquid` Break tag, this is used for a internal behavior of the `for` tag,
  creates a keyword list with a key `break` and the value is an empty list.
  """
  @spec break_tag() :: NimbleParsec.t()
  def break_tag, do: Tag.define_open("break")

  @doc """
  Parses a `Liquid` For tag, creates a Keyword list where the key is the name of the tag
  (for in this case) and the value is another keyword list which represents the internal
  structure of the tag.
  """
  @spec tag() :: NimbleParsec.t()
  def tag, do: Tag.define_block("for", &statements/1)

  defp statements(combinator) do
    combinator
    |> concat(LexicalToken.variable_value())
    |> concat(General.ignore_whitespaces())
    |> ignore(string("in"))
    |> concat(General.ignore_whitespaces())
    |> concat(LexicalToken.value())
    |> optional(params())
    |> concat(General.ignore_whitespaces())
    |> tag(:statements)
  end

  defp reversed_param do
    empty()
    |> concat(General.ignore_whitespaces())
    |> ignore(string("reversed"))
    |> concat(General.ignore_whitespaces())
    |> tag(:reversed)
  end

  defp params do
    empty()
    |> optional(
      times(
        choice([General.tag_param("offset"), General.tag_param("limit"), reversed_param()]),
        min: 1
      )
    )
    |> tag(:params)
  end
end
