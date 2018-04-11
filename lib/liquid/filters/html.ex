defmodule Liquid.Filters.HTML do
  @moduledoc """
  Applies a chain of 'HTML' filters passed from Liquid.Variable
  """
  import Kernel, except: [round: 1, abs: 1]
  import Liquid.Utils, only: [to_number: 1]

  alias Liquid.{HTML, Filters}

  use Timex

  @doc """
  Removes any newline characters (line breaks) from a string.
  """
  @spec strip_newlines(String.t()) :: String.t()
  def strip_newlines(<<string::binary>>) do
    String.replace(string, ~r/\r?\n/, "")
  end

  @doc """
  Replaces every newline (\n) with an HTML line break (<br>).
  """
  @spec newline_to_br(String.t()) :: String.t()
  def newline_to_br(<<string::binary>>) do
    String.replace(string, "\n", "<br />\n")
  end

  @doc """
  Escapes a string by replacing characters with escape sequences (so that the string can be used in a URL,
  for example). It doesn’t change strings that don’t have anything to escape.

  ## Examples

    iex> Liquid.Filters.Functions.escape("Have you read 'James & the Giant Peach'?")
    "Have you read &#39;James &amp; the Giant Peach&#39;?"
  """
  @spec escape(String.t()) :: String.t()
  def escape(input) when is_binary(input) do
    input |> HTML.html_escape()
  end

  defdelegate h(input), to: __MODULE__, as: :escape

  @doc """
  Escapes a string without changing existing escaped entities. It doesn’t change strings that don’t
  have anything to escape.

  ## Examples

    iex> Liquid.Filters.Functions.escape_once("1 < 2 & 3")
    "1 &lt; 2 &amp; 3"
  """
  @spec escape_once(String.t()) :: String.t()
  def escape_once(input) when is_binary(input) do
    input |> HTML.html_escape_once()
  end

  @doc """
  Removes any HTML tags from a string

  ## Examples

    iex> Liquid.Filters.Functions.strip_html("Have <em>you</em> read <strong>Ulysses</strong>?")
    "Have you read Ulysses?"
  """
  @spec strip_html(String.t()) :: String.t()
  def strip_html(nil), do: ""

  def strip_html(input) when is_binary(input) do
    input
    |> String.replace(~r/<script.*?<\/script>/m, "")
    |> String.replace(~r/<!--.*?-->/m, "")
    |> String.replace(~r/<style.*?<\/style>/m, "")
    |> String.replace(~r/<.*?>/m, "")
  end

  @doc """
  Converts any URL-unsafe characters in a string into percent-encoded characters.

  ## Examples

    iex> Liquid.Filters.Functions.url_encode("john@test.com")
    "john%40test.com"
  """
  @spec url_encode(String.t()) :: String.t()
  def url_encode(input) when is_binary(input) do
    input |> URI.encode_www_form()
  end

  def url_encode(nil), do: nil

end