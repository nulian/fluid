defmodule Liquid.Registers do
  @default_tags %{
    continue: {Liquid.Continue, Liquid.Tag},
    comment: {Liquid.Comment, Liquid.Block},
    include: {Liquid.Include, Liquid.Tag},
    assign: {Liquid.Assign, Liquid.Tag},
    block: {Liquid.Inherit, Liquid.Block},
    break: {Liquid.Break, Liquid.Tag},
    elsif: {Liquid.ElseIf, Liquid.Tag},
    else: {Liquid.Else, Liquid.Tag},
    case: {Liquid.Case, Liquid.Block},
    when: {Liquid.When, Liquid.Tag},
    for: {Liquid.ForElse, Liquid.Block},
    tablerow: {Liquid.TableRow, Liquid.Block},
    ifchanged: {Liquid.IfChanged, Liquid.Block},
    if: {Liquid.IfElse, Liquid.Block},
    unless: {Liquid.Unless, Liquid.Block},
    raw: {Liquid.Raw, Liquid.Block},
    increment: {Liquid.Increment, Liquid.Tag},
    decrement: {Liquid.Decrement, Liquid.Tag},
    cycle: {Liquid.Cycle, Liquid.Tag},
    capture: {Liquid.Capture, Liquid.Block}
  }

  def clear do
    Application.put_env(:liquid, :extra_tags, %{})
  end

  def lookup(name) when is_binary(name) do
    name |> String.to_atom() |> lookup
  end

  def lookup(name) when is_atom(name) do
    custom_tag =
      case Application.get_env(:liquid, :extra_tags) do
        %{^name => value} -> value
        _ -> nil
      end

    case {name, Map.get(@default_tags, name), custom_tag} do
      {nil, _, _} -> nil
      {_, nil, nil} -> nil
      {_, nil, custom_tag} -> custom_tag
      {_, tag, _} -> tag
    end
  end

  def lookup(_), do: nil

  def lookup(name, context) when is_binary(name) do
    name |> String.to_atom() |> lookup(context)
  end

  def lookup(name, %{extra_tags: extra_tags}) do
    custom_tag = Map.get(extra_tags, name)

    case {name, Map.get(@default_tags, name), custom_tag} do
      {nil, _, _} -> nil
      {_, nil, nil} -> nil
      {_, nil, custom_tag} -> custom_tag
      {_, tag, _} -> tag
    end
  end

  def lookup(_, _), do: nil

  def register(name, module, type) do
    custom_tags = Application.get_env(:liquid, :extra_tags) || %{}

    custom_tags =
      %{(name |> String.to_atom()) => {module, type}}
      |> Map.merge(custom_tags)

    Application.put_env(:liquid, :extra_tags, custom_tags)
  end
end
