defmodule Liquid.Translators.Tags.Increment do
  @moduledoc """
  Translate new AST to old AST for the Increment tag.
  """

  alias Liquid.Translators.Markup
  alias Liquid.Combinators.Tags.Increment
  alias Liquid.Tag

  @doc """
  Takes the markup of the new AST, creates a `Liquid.Tag` struct (old AST) and fill the keys needed to render a Increment tag.
  """
  @spec translate(Increment.markup()) :: Tag.t()
  def translate(markup) do
    variable_name = Keyword.get(markup, :variable)
    %Liquid.Tag{name: :increment, markup: "#{Markup.literal(variable_name)}"}
  end
end
