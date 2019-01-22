defmodule Liquid.Translators.Tags.Capture do
  @moduledoc """
  Translate new AST to old AST for the Capture tag.
  """
  alias Liquid.Translators.{General, Markup}
  alias Liquid.Combinators.Tags.Capture
  alias Liquid.Block

  @doc """
  Takes the markup of the new AST, creates a `Liquid.Block` struct (old AST) and fill the keys needed to render a Capture tag.
  """
  @spec translate(Capture.markup()) :: Block.t()
  def translate([variable, body: parts]) do
    nodelist =
      parts
      |> Liquid.NimbleTranslator.process_node()
      |> General.types_only_list()

    %Liquid.Block{
      name: :capture,
      markup: Markup.literal(variable),
      blank: true,
      nodelist: nodelist
    }
  end
end
