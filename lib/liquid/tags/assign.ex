defmodule Liquid.Assign do
  @moduledoc """
  Sets variables in a template
  ```
    {% assign foo = 'monkey' %}
  ```
  User can then use the variables later in the page.
  ```
    {{ foo }}
  ```
  """
  alias Liquid.{Context, Tag, Variable}

  def syntax, do: ~r/([\w\-]+)\s*=\s*(.*)\s*/

  @doc """
  Renders the Assign markup adding the rendered parts to the output list and returning it,
  in a tuple, with the new context.
  """
  @spec render(list(), %Tag{}, %Context{}) :: {list(), %Context{}}
  def render(output, %Tag{markup: markup}, %Context{} = context) do
    [[_, to, from]] = Regex.scan(syntax(), markup)

    {from_value, context} =
      from
      |> Variable.create()
      |> Variable.lookup(context)

    result_assign = context.assigns |> Map.put(to, from_value)
    context = %{context | assigns: result_assign}
    {output, context}
  end
end
