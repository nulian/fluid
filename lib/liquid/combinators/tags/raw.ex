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
  import NimbleParsec
  alias Liquid.Combinators.General

  @doc "Open raw tag: {% raw %}"
  def open_tag do
    General.start_tag()
    |> ignore(string("raw"))
    |> concat(General.end_tag())
  end

  @doc "Close raw tag: {% endraw %}"
  def close_tag do
    empty()
    |> parsec(:start_tag)
    |> ignore(string("endraw"))
    |> concat(parsec(:end_tag))
  end
end
