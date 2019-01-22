defmodule Liquid.Translators.Tags.Include do
  @moduledoc """
  Translate new AST to old AST for the Include tag.
  """

  alias Liquid.{Tag, Include}
  alias Liquid.Translators.Markup
  alias Liquid.Combinators.Tags.Include, as: IncludeCombinator

  @doc """
  Takes the markup of the new AST, creates a `Liquid.Tag` struct (old AST) and fill the keys needed to render a Include tag.
  """
  @spec translate(IncludeCombinator.markup()) :: Tag.t()
  def translate([snippet]), do: parse("'#{Markup.literal(snippet)}'")

  def translate([snippet, rest]),
    do: parse("'#{Markup.literal(snippet)}' #{Markup.literal(rest)}")

  defp parse(markup) do
    Include.parse(%Tag{markup: markup, name: :include})
  end
end
