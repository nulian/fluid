defmodule Liquid.Cycle do
  @moduledoc """
  Implementation of `cycle` tag. Can be named or anonymous, rotates through pre-set values
  Cycle is usually used within a loop to alternate between values, like colors or DOM classes.
  """
  alias Liquid.{Tag, Template, Context, Variable}

  @colon_parser ~r/\:(?=(?:[^'"]|'[^']*'|"[^"]*")*$)/
  #  @except_colon_parser ~r/(?:[^:"']|"[^"]*"|'[^']*')+/

  @doc """
  Sets up the cycle name and variables to cycle through
  """
  def parse(%Tag{markup: markup} = tag, %Template{} = template) do
    {name, values} = markup |> get_name_and_values
    tag = %{tag | parts: [name | values]}
    {tag, template}
  end

  @doc """
  Returns a corresponding cycle value and increments the cycle counter
  """
  def render(output, %Tag{parts: [name | values]}, %Context{} = context) do
    {name, context} = Variable.lookup(%Variable{parts: [], literal: name}, context)
    name = to_string(name) <> "_liquid_cycle"
    {rendered, context} = Variable.lookup(%Variable{parts: [name], literal: nil}, context)
    index = rendered || 0
    {value, context} = values |> Enum.fetch!(index) |> get_value_from_context(context)
    new_index = rem(index + 1, Enum.count(values))
    result_assign = Map.put(context.assigns, name, new_index)
    {[value | output], %{context | assigns: result_assign}}
  end

  defp get_value_from_context(name, context) do
    custom_value = Liquid.Appointer.parse_name(name)

    parsed =
      if custom_value |> Map.has_key?(:parts),
        do: List.first(custom_value.parts),
        else: custom_value.literal

    variable = %Variable{parts: [], literal: parsed}
    Variable.lookup(variable, context)
  end

  defp get_name_and_values(markup) do
    [name | values] = markup |> String.split(@colon_parser, parts: 2, trim: true)
    values = if values == [], do: [name], else: values
    values = values |> hd |> String.split(",", trim: true) |> Enum.map(&String.trim(&1))
    {name, values}
  end
end
