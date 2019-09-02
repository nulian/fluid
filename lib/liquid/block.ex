defmodule Liquid.Block do
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

  def create(markup) do
    destructure [name, rest], String.split(markup, " ", parts: 2)
    %Block{name: name |> String.trim() |> String.to_atom(), markup: rest}
  end

  def split(nodes), do: split(nodes, [:else])
  def split(%Block{nodelist: nodelist}, namelist), do: split(nodelist, namelist)

  def split(nodelist, namelist) when is_list(nodelist) do
    Enum.split_while(nodelist, fn x ->
      !(is_map(x) and x.__struct__ == Tag and Enum.member?(namelist, x.name))
    end)
  end
end
