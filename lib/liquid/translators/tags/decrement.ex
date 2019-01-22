defmodule Liquid.Translators.Tags.Decrement do
  @moduledoc """
  Translate new AST to old AST for the Decrement tag.
  """

  alias Liquid.Translators.Markup
  alias Liquid.Combinators.Tags.Decrement
  alias Liquid.Tag

  @doc """
  Takes the markup of the new AST, creates a `Liquid.Tag` struct (old AST) and fill the keys needed to render a Decrement tag.
  """
  @spec translate(Decrement.markup()) :: Tag.t()
  def translate(markup) do
    variable_name = Keyword.get(markup, :variable)
    %Liquid.Tag{name: :decrement, markup: Markup.literal(variable_name)}
  end
end
