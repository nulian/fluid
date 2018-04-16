# relies to https://github.com/elixir-lang/plug/blob/master/lib/plug/html.ex
defmodule Liquid.HTML do
  @moduledoc """
  Conveniences for generating HTML.
  """

  @doc ~S"""
  Escapes the given HTML.

      iex> Plug.HTML.html_escape("<foo>")
      "&lt;foo&gt;"

      iex> Plug.HTML.html_escape("quotes: \" & \'")
      "quotes: &quot; &amp; &#39;"
  """
  def html_escape(data) when is_binary(data) do
    IO.iodata_to_binary(for <<char <- data>>, do: escape_char(char))
  end

  @compile {:inline, escape_char: 1}

  @escapes [
    {?<, "&lt;"},
    {?>, "&gt;"},
    {?&, "&amp;"},
    {?", "&quot;"},
    {?', "&#39;"}
  ]
  @escapes_map %{"<" => "&lt;", ">" => "&gt;", "&" => "&amp;", "\"" => "&quot;", "'" => "&#39;"}

  @escape_regex ~r/["><']|&(?!([a-zA-Z]+|(#\d+));)/

  def html_escape_once(data) when is_binary(data) do
    Regex.replace(@escape_regex, data, fn v, _ -> @escapes_map[v] end)
  end

  Enum.each(@escapes, fn {match, insert} ->
    defp escape_char(unquote(match)), do: unquote(insert)
  end)

  defp escape_char(char), do: char
end

defmodule Liquid.Utils do
  @moduledoc """
  A number of useful utils for liquid parser/filters
  """

  @doc """
  Converts various input to number for further processing
  """
  def to_number(nil), do: 0

  def to_number(input) when is_number(input), do: input

  def to_number(input) when is_binary(input) do
    case Integer.parse(input) do
      {integer, ""} ->
        integer

      :error ->
        0

      {integer, remainder} ->
        case Float.parse(input) do
          {_, float_remainder} when float_remainder == remainder ->
            integer

          {float, _} ->
            float
        end
    end
  end
end
