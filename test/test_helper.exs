ExUnit.start(exclude: [:skip])

defmodule Liquid.Helpers do
  use ExUnit.Case

  def render(text, data \\ %{}) do
    text |> Liquid.Template.parse() |> Liquid.Template.render(data) |> elem(1)
  end

  def test_combinator(markdown, combiner, expected) do
    {:ok, response, _, _, _, _} = combiner.(markdown)
    assert response == expected
  end

  def test_combinator_error(markdown, combiner, expected) do
    {:error, response, _, _, _, _} = combiner.(markdown)
    assert response == expected
  end
end
