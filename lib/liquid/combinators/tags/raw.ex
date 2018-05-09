defmodule Liquid.Combinators.Tags.Raw do
  @moduledoc """
  Temporarily disables tag processing. This is useful for generating content (eg, Mustache, Handlebars)
  which uses conflicting syntax.
  Input:
  ```
    {% raw %}
    In Handlebars, {{ this }} will be HTML-escaped, but
    {{{ that }}} will not.
    {% endraw %}
  ```
  Output:
  ```
  In Handlebars, {{ this }} will be HTML-escaped, but {{{ that }}} will not.
  ```
  """
  alias Liquid.Combinators.General
  import NimbleParsec

  @doc "Open raw tag: {% raw %}"
  def open_tag do
    empty()
    |> parsec(:start_tag)
    |> ignore(string("raw"))
    |> concat(parsec(:end_tag))
  end

  @doc "Close raw tag: {% endraw %}"
  def close_tag do
    empty()
    |> parsec(:start_tag)
    |> ignore(string("endraw"))
    |> concat(parsec(:end_tag))
  end

  def not_close_tag_raw do
    empty()
    |> ignore(utf8_char([]))
    |> parsec(:raw_content)
  end

  def raw_content do
    empty()
    |> repeat_until(utf8_char([]), [
      string(General.codepoints().start_tag)
    ])
    |> choice([parsec(:close_tag_raw), parsec(:not_close_tag_raw)])
    |> reduce({List, :to_string, []})
    |> tag(:raw_content)
  end

  def tag do
    empty()
    |> parsec(:open_tag_raw)
    |> concat(parsec(:raw_content))
    |> tag(:raw)
    |> optional(parsec(:__parse__))
  end
end
