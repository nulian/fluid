defprotocol Blank do
  @doc "Returns true when blank"
  def blank?(data)
end

defimpl Blank, for: List do
  alias Liquid.{Block, Tag}

  @spec blank?(list()) :: boolean()
  def blank?([]), do: true

  def blank?(list) do
    list
    |> Enum.all?(fn
      x when is_binary(x) -> !!Regex.match?(~r/\A\s*\z/, x)
      %Block{blank: true} -> true
      %Tag{blank: true} -> true
      _ -> false
    end)
  end
end
