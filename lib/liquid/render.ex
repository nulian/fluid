defmodule Liquid.Render do
  alias Liquid.Variable
  alias Liquid.Template
  alias Liquid.Registers
  alias Liquid.Context
  alias Liquid.Block
  alias Liquid.Tag

  def render(%Template{root: root}, %Context{} = context, options) do
    {output, context} = render([], root, context, options)
    {:ok, output |> to_text, context}
  end

  def render(output, [], %Context{} = context, options) do
    {output, context}
  end

  def render(output, [h | t], %Context{} = context, options) do
    {output, context} = render(output, h, context)

    case context do
      %Context{extended: false, break: false, continue: false} -> render(output, t, context)
      _ -> render(output, [], context)
    end
  end

  def render(output, text, %Context{} = context, options) when is_binary(text) do
    {[text | output], context}
  end

  def render(output, %Variable{} = variable, %Context{} = context, options) do
    {rendered, context} = Variable.lookup(variable, context, options)
    {[join_list(rendered) | output], context}
  end

  def render(output, %Tag{name: name} = tag, %Context{} = context, options) do
    {mod, Tag} = Registers.lookup(name, options)
    mod.render(output, tag, context)
  end

  def render(output, %Block{name: name} = block, %Context{} = context, options) do
    case Registers.lookup(name, options) do
      {mod, Block} -> mod.render(output, block, context)
      nil -> render(output, block.nodelist, context)
    end
  end

  def to_text(list), do: list |> List.flatten() |> Enum.reverse() |> Enum.join()

  defp join_list(input) when is_list(input), do: input |> List.flatten() |> Enum.join()

  defp join_list(input), do: input
end
