defmodule Liquid.Tag do
  @moduledoc """
  Defines and create the tag structures 
  """
  defstruct name: nil, markup: nil, parts: [], attributes: [], blank: false
  alias Liquid.Tag

  @doc """
  Create a new tag struct
  """
  @spec create(String.t()) :: %Tag{}
  def create(markup) do
    destructure [name, rest], String.split(markup, " ", parts: 2)
    %Liquid.Tag{name: String.to_atom(name), markup: rest}
  end
end
