defmodule Liquid.Translators.Tags.Cycle do
  @moduledoc """
  Translate new AST to old AST for the Cycle tag.
  """

  alias Liquid.Translators.Markup
  alias Liquid.Combinators.Tags.Cycle
  alias Liquid.Tag

  @doc """
  Takes the markup of the new AST, creates a `Liquid.Tag` struct (old AST) and fill the keys needed to render a Cycle tag.
  """
  @spec translate(Cycle.markup()) :: Tag.t()
  def translate(values: values) do
    parts = Enum.map(values, &cycle_to_string/1)
    markup = Markup.literal(parts, ", ")
    %Liquid.Tag{name: :cycle, markup: markup, parts: [markup | parts]}
  end

  def translate(group: [cycle_group_value], values: cycle_values) do
    cycle_value_in_parts = Enum.map(cycle_values, &cycle_to_string/1)
    markup = cycle_group_value <> ": " <> Markup.literal(cycle_value_in_parts, ", ")
    parts = [cycle_group_value | cycle_value_in_parts]

    %Liquid.Tag{name: :cycle, markup: markup, parts: parts}
  end

  defp cycle_to_string(value) when is_bitstring(value), do: "'#{value}'"
  defp cycle_to_string(nil), do: "null"
  defp cycle_to_string(value), do: "#{Markup.literal(value)}"
end
