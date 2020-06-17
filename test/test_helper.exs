ExUnit.start(exclude: [:skip])

defmodule Liquid.Helpers do
  def render(name, text, data \\ %{}) do
    parsed_template = Liquid.parse_template(name, text)
    name |> Liquid.render_template(parsed_template, data) |> elem(1)
  end
end
