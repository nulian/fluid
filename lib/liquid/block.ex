defmodule Liquid.Block do
  @moduledoc "A module to define Block struct of tags, variables used by parse"

  defstruct name: nil,
            markup: nil,
            condition: nil,
            parts: [],
            iterator: [],
            nodelist: [],
            elselist: [],
            blank: false,
            strict: true

  alias Liquid.Tag, as: Tag
  alias Liquid.Block, as: Block

  @doc "Creates a standard Block structure from a markup. Blocks are standard data structures resulting from a markup processing"
  def create(markup) do
    destructure [name, rest], String.split(markup, " ", parts: 2)
    %Block{name: name |> String.to_atom(), markup: rest}
  end

  @doc "Splits a standard Block structure from a markup"
  def split(nodes), do: split(nodes, [:else])
  def split(%Block{nodelist: nodelist}, namelist), do: split(nodelist, namelist)

  def split(nodelist, namelist) when is_list(nodelist) do
    Enum.split_while(nodelist, fn x ->
      !(is_map(x) and x.__struct__ == Tag and Enum.member?(namelist, x.name))
    end)
  end
end
