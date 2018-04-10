defmodule Liquid.Case do
  @moduledoc """
   Creates a switch statement to compare a variable with different values.
   Case initializes the switch statement, and When compares its values.
  Input:
    ```
      {% assign handle = 'cake' %}
      {% case handle %}
      {% when 'cake' %}
        This is a cake
      {% when 'cookie' %}
        This is a cookie
      {% else %}
        This is not a cake nor a cookie
      {% endcase %}
    ```
  Output:
    ```
      This is a cake
    ```
  """
  alias Liquid.{Block, Condition, Tag, Template, Variable}

  @doc """
  Returns a regex for Case expressions syntax validation
  """
  def syntax, do: ~r/(#{Liquid.quoted_fragment()})/

  @doc """
  Returns a regex for When expressions syntax validation
  """
  def when_syntax,
    do: ~r/(#{Liquid.quoted_fragment()})(?:(?:\s+or\s+|\s*\,\s*)(#{Liquid.quoted_fragment()}.*))?/

  @doc """
  Implementation of Capture parse operations
  """
  @spec parse(%Block{}, %Template{}) :: {%Block{}, %Template{}}
  def parse(%Block{markup: markup} = b, %Template{} = t) do
    [[_, name]] = syntax() |> Regex.scan(markup)
    {split(name |> Variable.create(), b.nodelist), t}
  end

  defp split(%Variable{}, []), do: []

  defp split(%Variable{} = v, [h | t]) when is_binary(h), do: split(v, t)

  defp split(%Variable{}, [%Liquid.Tag{name: :else} | t]), do: t

  defp split(%Variable{} = v, [%Liquid.Tag{name: :when, markup: markup} | t]) do
    {nodelist, t} = Block.split(t, [:when, :else])
    condition = parse_condition(v, markup)
    %Block{name: :if, nodelist: nodelist, condition: condition, elselist: split(v, t)}
  end

  defp parse_condition(%Variable{} = v, <<markup::binary>>) do
    {h, t} = parse_when(markup)
    parse_condition(v, Condition.create({v, "==", h}), t)
  end

  defp parse_condition(%Variable{} = _, %Condition{} = condition, []), do: condition

  defp parse_condition(%Variable{} = v, %Condition{} = condition, [<<markup::binary>>]) do
    {h, t} = parse_when(markup)
    parse_condition(v, Condition.join(:or, condition, {v, "==", h}), t)
  end

  defp parse_when(markup) do
    [[_, h | t] | m] = when_syntax() |> Regex.scan(markup)
    m = m |> List.flatten() |> Liquid.List.even_elements()
    t = [t | m] |> Enum.join(" ")
    t = if t == "", do: [], else: [t]
    {h, t}
  end
end

defmodule Liquid.When do
  @moduledoc """
   Defines When implementations (sub-component of Case). Case creates a switch statement to compare a variable with different values.
   Case initializes the switch statement, and When compares its values.
  """
  alias Liquid.{Tag, Template}

  @doc """
  Identity function. Implementation of When (sub-component of Case) parse operations
  """
  @spec parse(%Tag{}, %Template{}) :: {%Tag{}, %Template{}}
  def parse(%Tag{} = tag, %Template{} = t), do: {tag, t}
end
