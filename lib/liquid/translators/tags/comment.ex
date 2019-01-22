defmodule Liquid.Translators.Tags.Comment do
  @moduledoc """
  Translate new AST to old AST for the Comment tag.
  """

  alias Liquid.Combinators.Tags.Comment
  alias Liquid.Block

  @doc """
  Takes the markup of the new AST, creates a `Liquid.Block` struct (old AST) and fill the keys needed to render a Comment tag.
  """
  @spec translate(Comment.markup()) :: Block.t()
  def translate(_markup) do
    %Liquid.Block{name: :comment, blank: true, strict: false, nodelist: [""]}
  end
end
