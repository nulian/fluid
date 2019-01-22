defmodule Liquid.ElseIf do
  def render(_, _, _, _), do: raise("should never get here")
end

defmodule Liquid.Else do
  def render(_, _, _, _), do: raise("should never get here")
end

defmodule Liquid.IfElse do
  alias Liquid.Condition
  alias Liquid.Render
  alias Liquid.Block
  alias Liquid.Tag

  def syntax,
    do: ~r/(#{Liquid.quoted_fragment()})\s*([=!<>a-z_]+)?\s*(#{Liquid.quoted_fragment()})?/

  def expressions_and_operators do
    ~r/(?:\b(?:\s?and\s?|\s?or\s?)\b|(?:\s*(?!\b(?:\s?and\s?|\s?or\s?)\b)(?:#{
      Liquid.quoted_fragment()
    }|\S+)\s*)+)/
  end

  def render(output, %Tag{}, context) do
    {output, context}
  end

  def render(output, %Block{blank: true} = block, context) do
    {_, context} = render(output, %{block | blank: false}, context)
    {output, context}
  end

  def render(
        output,
        %Block{condition: condition, nodelist: nodelist, elselist: elselist, blank: false},
        context
      ) do
    condition = Condition.evaluate(condition, context)
    conditionlist = if condition, do: nodelist, else: elselist
    Render.render(output, conditionlist, context)
  end

  defp split_conditions(expressions) do
    expressions
    |> List.flatten()
    |> Enum.map(&String.trim/1)
    |> Enum.map(fn x ->
      case syntax() |> Regex.scan(x) do
        [[_, left, operator, right]] -> {left, operator, right}
        [[_, x]] -> x
        _ -> raise Liquid.SyntaxError, message: "Check the parenthesis"
      end
    end)
  end

  def parse_conditions(%Block{markup: markup} = block) do
    expressions = Regex.scan(expressions_and_operators(), markup)
    expressions = expressions |> split_conditions |> Enum.reverse()
    condition = Condition.create(expressions)
    # Check condition syntax
    Condition.evaluate(condition)
    %{block | condition: condition}
  end
end
