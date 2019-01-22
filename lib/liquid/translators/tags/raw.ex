defmodule Liquid.Translators.Tags.Raw do
  alias Liquid.Translators.Markup

  @moduledoc """
  Translate new AST to old AST for Raw tag.
  """

  alias Liquid.Block

  @doc """
  Takes the markup of the new AST, creates a `Liquid.Block` struct (old AST) and fill the keys needed to render a Raw tag.
  """
  @spec translate(String.t()) :: Block.t()
  def translate([markup]) do
    %Liquid.Block{name: :raw, strict: false, nodelist: ["#{Markup.literal(markup)}"]}
  end
end
