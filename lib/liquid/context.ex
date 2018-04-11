defmodule Liquid.Context do
  @moduledoc """
  This module creates a structure `(Structs)` that gives the context for rendering
  """
  defstruct assigns: %{},
            offsets: %{},
            registers: %{},
            presets: %{},
            blocks: [],
            extended: false,
            continue: false,
            break: false,
            template: nil,
            global_filter: nil,
            extra_tags: %{}

  @doc """
  Takes the context struct and get the selected key associated value
  """
  def registers(context, key), do: Map.get(context.registers, key)
end
