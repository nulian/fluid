ExUnit.start(exclude: [:skip])

defmodule Liquid.Helpers do
  def render(text, data \\ %{}) do
    text |> Liquid.Template.parse() |> Liquid.Template.render(data) |> elem(1)
  end
end
