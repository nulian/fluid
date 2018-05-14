defmodule Liquid.Combinators.Tags.Assign do
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

  def tag do
    empty()
    |> parsec(:start_tag)
    |> concat(ignore(string("assign")))
    |> concat(parsec(:variable_name))
    |> concat(ignore(string("=")))
    |> concat(parsec(:value))
    |> concat(parsec(:end_tag))
    |> tag(:assign)
    |> optional(parsec(:__parse__))
  end
end
