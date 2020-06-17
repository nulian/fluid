defmodule Liquid.Case do
  alias Liquid.Tag
  alias Liquid.Block
  alias Liquid.Template
  alias Liquid.Variable
  alias Liquid.Condition

  @compile {:inline, syntax: 0}
  def syntax, do: ~r/(#{Liquid.Parse.quoted_fragment()})/

  @compile {:inline, when_syntax: 0}
  def when_syntax,
    do: ~r/(#{Liquid.Parse.quoted_fragment()})(?:(?:\s+or\s+|\s*\,\s*)(#{Liquid.Parse.quoted_fragment()}.*))?/

  def parse(%Block{markup: markup} = b, %Template{} = t, _options) do
    [[_, name]] = syntax() |> Regex.scan(markup)
    {split(name |> Variable.create(), b.nodelist), t}
  end

  defp split(%Variable{}, []), do: []
  defp split(%Variable{} = v, [h | t]) when is_binary(h), do: split(v, t)
  defp split(%Variable{} = _, [%Liquid.Tag{name: :else} | t]), do: t

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
  alias Liquid.Tag, as: Tag
  alias Liquid.Template, as: Template

  def parse(%Tag{} = tag, %Template{} = t, _options), do: {tag, t}
end
