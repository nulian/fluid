defmodule Liquid.Tokenizer do
  @moduledoc """
  Prepares markup to be parsed. Tokenizer splits the code between starting literal and rest of markup.
  When called recursively, it allows to process only liquid part (tags and variables) and bypass the slower literal.
  """

  alias Liquid.Combinators.General

  @doc """
  Takes a markup, find start of liquid construction (tag or variable) and returns
  a tuple with two elements: a literal and rest(with tags/variables and optionally more literals)
  """
  @spec tokenize(String.t()) :: {String.t(), String.t()}
  def tokenize(markup) do
    case :binary.match(markup, [
           General.codepoints().start_tag,
           General.codepoints().start_variable
         ]) do
      :nomatch -> {markup, ""}
      {0, _} -> {"", markup}
      {start, _} -> split(markup, start)
    end
  end

  defp split(markup, start) do
    len = byte_size(markup)
    literal = :binary.part(markup, {0, start})
    rest_markup = :binary.part(markup, {len, start - len})
    {literal, rest_markup}
  end
end
