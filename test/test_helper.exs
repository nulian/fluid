ExUnit.start(exclude: [:skip])

defmodule Liquid.Helpers do
  use ExUnit.Case

  def render(text, data \\ %{}) do
    text |> Liquid.Template.parse() |> Liquid.Template.render(data) |> elem(1)
  end

  def test_combinator(markup, combiner, expected) do
    {:ok, response, _, _, _, _} = combiner.(markup)
    assert response == expected
  end

  def test_combinator_error(markup, combiner) do
    {:error, _, _, _, _, _} = combiner.(markup)
    assert true
  end
end
