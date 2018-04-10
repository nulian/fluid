defmodule Liquid.Registers do
  @moduledoc """
  Provides a register of tags, returns tags by name.
  Also allows add custom tags
  """
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

  @doc """
  Delete extra tags from Registers.
  """
  def clear do
    Application.put_env(:liquid, :extra_tags, %{})
  end

  @doc """
  It search for the valids tags on the register, even if it is a custom one.
  """
  @spec lookup(String.t(), %{}) :: %{}
  def lookup(name, context \\ %{})

  def lookup(name, context) when is_binary(name) do
    name |> String.to_atom() |> lookup(context)
  end

  def lookup(name, context) when is_atom(name) do
    custom_tag =
      get_in(context, [:extra_tags, name]) ||
        Map.get(Application.get_env(:liquid, :extra_tags, %{}), name)

    case {name, Map.get(@default_tags, name), custom_tag} do
      {nil, _, _} -> nil
      {_, nil, nil} -> nil
      {_, nil, custom_tag} -> custom_tag
      {_, tag, _} -> tag
    end
  end

  def lookup(_, _), do: nil

  @doc """
  Add tag to Registers
  """
  @spec register(String.t(),String.t(), String.t()) :: %{}
  def register(name, module, type) do
    custom_tags =
      Map.merge(Application.get_env(:liquid, :extra_tags, %{}), %{
        String.to_atom(name) => {module, type}
      })

    Application.put_env(:liquid, :extra_tags, custom_tags)
  end
end
