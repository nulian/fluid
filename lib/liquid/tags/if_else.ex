defmodule Liquid.ElseIf do
  def parse(%Liquid.Tag{} = tag, %Liquid.Template{} = t, _options), do: {tag, t}
  def render(_, _, _, _, _), do: raise("should never get here")
end

defmodule Liquid.Else do
  def parse(%Liquid.Tag{} = tag, %Liquid.Template{} = t, _options), do: {tag, t}
  def render(_, _, _, _, _), do: raise("should never get here")
end

defmodule Liquid.IfElse do
  alias Liquid.Condition
  alias Liquid.Render
  alias Liquid.Block
  alias Liquid.Tag
  alias Liquid.Template

  @compile {:inline, syntax: 0}
  def syntax,
    do:
      ~r/(#{Liquid.Parse.quoted_fragment()})\s*([=!<>a-z_]+)?\s*(#{Liquid.Parse.quoted_fragment()})?/

  @compile {:inline, expressions_and_operators: 0}
  def expressions_and_operators do
    ~r/(?:\b(?:\s?and\s?|\s?or\s?)\b|(?:\s*(?!\b(?:\s?and\s?|\s?or\s?)\b)(?:#{Liquid.Parse.quoted_fragment()}|\S+)\s*)+)/
  end

  def parse(%Block{} = block, %Template{} = t, options) do
    block = parse_conditions(block, options)

    case Block.split(block, [:else, :elsif]) do
      {true_block, [%Tag{name: :elsif, markup: markup} | elsif_block]} ->
        {elseif, t} =
          parse(
            %Block{
              name: :if,
              markup: markup,
              nodelist: elsif_block,
              blank: Blank.blank?(elsif_block)
            },
            t,
            options
          )

        {%{block | nodelist: true_block, elselist: [elseif], blank: Blank.blank?(true_block)}, t}

      {true_block, [%Tag{name: :else} | false_block]} ->
        blank? = Blank.blank?(true_block) && Blank.blank?(false_block)
        {%{block | nodelist: true_block, elselist: false_block, blank: blank?}, t}

      {_, []} ->
        {%{block | blank: Blank.blank?(block.nodelist)}, t}
    end
  end

  def render(output, %Tag{}, context, _options) do
    {output, context}
  end

  def render(output, %Block{blank: true} = block, context, options) do
    {_, context} = render(output, %{block | blank: false}, context, options)
    {output, context}
  end

  def render(
        output,
        %Block{condition: condition, nodelist: nodelist, elselist: elselist, blank: false},
        context,
        options
      ) do
    condition = Condition.evaluate(condition, context, options)
    conditionlist = if condition, do: nodelist, else: elselist
    Render.render(output, conditionlist, context, options)
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

  defp parse_conditions(%Block{markup: markup} = block, options) do
    markup = change_wrong_markup(markup)
    expressions = Regex.scan(expressions_and_operators(), markup)
    expressions = expressions |> split_conditions |> Enum.reverse()
    condition = Condition.create(expressions)
    # Check condition syntax
    Condition.evaluate(condition, options)
    %{block | condition: condition}
  end

  defp change_wrong_markup(markup) do
    markup
    |> String.replace("| lt:", "<")
    |> String.replace("| gt:", ">")
    |> String.replace("| gte:", ">=")
    |> String.replace("| lte:", "<=")
    |> String.replace("&&", "and")
    |> String.replace("||", "or")
  end
end
