defmodule Liquid.Tag do
  defstruct name: nil, markup: nil, parts: [], attributes: [], blank: false, end_marker: false

  def create(markup) when is_binary(markup) do
    destructure [name, rest], String.split(markup, " ", parts: 2)
    %Liquid.Tag{name: name |> String.to_atom, markup: rest}
  end
  def create(nil), do: nil

  def create(name, arguments) do
    %Liquid.Tag{name: name, markup: arguments |> to_string()}
  end

end
