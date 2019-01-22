defmodule Liquid.Capture do
  @moduledoc """
  Stores the result of a block into a variable without rendering it inplace.
  ```
    {% capture heading %}
      Monkeys!
    {% endcapture %}
    ...
    <h1>{{ heading }}</h1>
  ```
  Capture is useful for saving content for use later in your template, such as in a sidebar or footer.
  """
  alias Liquid.{Block, Render, Context}

  @doc """
  Renders the Capture markup adding the rendered parts to the output list and returning it,
  in a tuple, with the new context.
  """
  @spec render(list(), %Block{}, %Context{}) ::
          {list(), %Context{}} | {list(), %Block{}, %Context{}}
  def render(output, %Block{markup: markup, nodelist: content}, %Context{} = context) do
    variable_name = Liquid.variable_parser() |> Regex.run(markup) |> hd
    {block_output, context} = Render.render([], content, context)

    result_assign = context.assigns |> Map.put(variable_name, block_output |> Render.to_text())

    context = %{context | assigns: result_assign}
    {output, context}
  end
end
