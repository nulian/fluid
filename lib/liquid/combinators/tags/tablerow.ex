defmodule Liquid.Combinators.Tags.Tablerow do
  @moduledoc """
  Iterates over an array or collection splitting it up to a table with pre-set columns number
  Several useful variables are available to you within the loop.
  Generates an HTML table. Must be wrapped in opening <table> and closing </table> HTML tags.
  Input:
  ```
    <table>
      {% tablerow product in collection.products %}
        {{ product.title }}
      {% endtablerow %}
    </table>
  ```
  Output:
  ```
    <table>
    <tr class="row1">
      <td class="col1">
        Cool Shirt
      </td>
      <td class="col2">
        Alien Poster
      </td>
      <td class="col3">
        Batman Poster
      </td>
      <td class="col4">
        Bullseye Shirt
      </td>
      <td class="col5">
        Another Classic Vinyl
      </td>
      <td class="col6">
        Awesome Jeans
      </td>
    </tr>
    </table>
  ```
  """
  import NimbleParsec
  alias Liquid.Combinators.{General, Tag, LexicalToken}

  @type t :: [tablerow: Tablerow.markup()]

  @type markup :: [
          statements: [
            variable: Liquid.Combinators.LexicalToken.variable_value(),
            value: Liquid.Combinators.LexicalToken.value()
          ],
          params: [limit: [LexicalToken.value()], cols: [LexicalToken.value()]],
          body: Liquid.NimbleParser.t()
        ]

  @doc """
  Parses a `Liquid` Tablerow tag, creates a Keyword list where the key is the name of the tag
  (tablerow in this case) and the value is another keyword list which represents the internal
  structure of the tag.
  """
  @spec tag() :: NimbleParsec.t()
  def tag do
    Tag.define_block("tablerow", &statements/1)
  end

  defp params do
    empty()
    |> times(
      choice([General.tag_param("offset"), General.tag_param("cols"), General.tag_param("limit")]),
      min: 1
    )
    |> optional()
    |> tag(:params)
  end

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
end
