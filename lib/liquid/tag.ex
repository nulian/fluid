defmodule Liquid.Tag do
  defstruct name: nil, markup: nil, parts: [], attributes: [], blank: false

  @type t :: %Liquid.Tag{
          name: String.t() | nil,
          markup: String.t() | nil,
          parts: [...],
          attributes: [...],
          blank: boolean()
        }

  def create(markup) do
    destructure [name, rest], String.split(markup, " ", parts: 2)
    %Liquid.Tag{name: name |> String.to_atom(), markup: rest}
  end
end
