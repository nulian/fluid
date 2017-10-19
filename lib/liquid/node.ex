defmodule Liquid.Node do
  @moduledoc false

  alias Liquid.Registers
  alias Liquid.{Block, Tag}

  def create({'end' ++ name, arguments}) do
    create(name |> to_string |> String.to_existing_atom(), arguments, [end_marker: true])
  end

  def create({name, arguments}) do
    create(name |> to_string |> String.to_existing_atom(), arguments, [])
  end

  def create(name, arguments, options) do
    arguments = arguments |> to_string |> String.trim()
    case Registers.lookup(name) do
      {_mod, Block} ->
        Block.create(name, arguments, options)
      {_mod, Tag} ->
        Tag.create(name, arguments)
      nil -> raise "unregistered tag: #{name}"
    end
  end

end
