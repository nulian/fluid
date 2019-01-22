defmodule Liquid.Comment do
  def render(output, %Liquid.Block{}, context), do: {output, context}
end
