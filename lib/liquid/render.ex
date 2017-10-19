defmodule Liquid.Render do
  alias Liquid.Variable
  alias Liquid.Template
  alias Liquid.Registers
  alias Liquid.Context
  alias Liquid.Block
  alias Liquid.Tag

  def render(%Template{root: root}, %Context{version: 2} = context) do
    { output, context } = render([], root, context)
    { :ok, output |> to_text(2), context }
  end

  def render(%Template{root: root}, %Context{version: 1}=context) do
    { output, context } = render([], root, context)
    { :ok, output |> to_text, context }
  end

  def render(output, [], %Context{}=context) do
    { output, context }
  end

  def render(output, [h|t], %Context{}=context) do
    { output, context } = render(output, h, context)
    case context do
      %Context{extended: false, break: false, continue: false} -> render(output, t, context)
      _ -> render(output, [], context)
    end
  end

  def render(output, {:string, char_list}, %Context{} = context) do
    { [char_list|output] , context }
  end

  def render(output, text, %Context{}=context) when is_binary(text) do
    { [text|output] , context }
  end

  def render(output, %Variable{}=v, %Context{version: 2}=context) do
    rendered = Variable.lookup(v, context)
    { [rendered|output], context }
  end

  def render(output, %Variable{}=v, %Context{}=context) do
    rendered = Variable.lookup(v, context) |> join_list
    { [rendered|output], context }
  end

  def render(output, %Tag{name: name}=tag, %Context{}=context) do
    { mod, Tag } = Registers.lookup(name, context)
    mod.render(output, tag, context)
  end

  def render(output, %Block{name: name}=block, %Context{}=context) do
    case Registers.lookup(name, context) do
      { mod, Block } -> mod.render(output, block, context)
      nil ->
        render(output, block.nodelist, context)
    end
  end

  def to_text(list, 2), do: list |> Enum.reverse |> List.flatten |> Enum.join
  def to_text(list), do: list |> List.flatten |> Enum.reverse |> Enum.join

  defp join_list(input) when is_list(input),
   do: input |> List.flatten |> Enum.join

  defp join_list(input), do: input

end
