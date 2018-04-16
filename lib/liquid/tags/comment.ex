defmodule Liquid.Comment do
  def parse(%Liquid.Block{} = block, %Liquid.Template{} = template),
    do: {%{block | blank: true, strict: false}, template}

  def render(output, %Liquid.Block{}, context), do: {output, context}
end
