defmodule Liquid.Comment do
  def parse(%Liquid.Block{} = block, %Liquid.Template{} = template, _options),
    do: {%{block | blank: true, strict: false}, template}

  def render(output, %Liquid.Block{}, context, _options), do: {output, context}
end
