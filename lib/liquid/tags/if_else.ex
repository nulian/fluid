defmodule Liquid.ElseIf do
  @moduledoc """
  Adds more conditions within an if or unless block.
  Input:
  ```
    <!-- If customer.name = 'anonymous' -->
    {% if customer.name == 'kevin' %}
    Hey Kevin!
    {% elsif customer.name == 'anonymous' %}
    Hey Anonymous!
    {% else %}
    Hi Stranger!
    {% endif %}
  ```
  Output:
  ```
    Hey Anonymous!
  ```
  """
  @doc """
  Implementation of 'ElseIf' parse operations
  """
  alias Liquid.{Context, Tag, Template}

  @spec parse(%Tag{}, %Template{}) :: {%Tag{}, %Template{}}
  def parse(%Tag{} = tag, %Template{} = t), do: {tag, t}

  @doc """
  Implementation of 'ElseIf' render operations
  """
  def render(_, _, _, _), do: raise("should never get here")
end

defmodule Liquid.Else do
  @moduledoc """
  Executes a block of code only if a certain condition is true. If this condition is false executes else block of code
  Input:
  ```
    {% if product.title == 'Awesome Shoes' %}
    These shoes are awesome!
    {% else %}
    These shoes are ugly!
    {% endif %}
  ```
   Output:
  ```
     These shoes are ugly!
  ```
  """

  @doc """
  Identity function. Implementation of 'Else' parse operations
  """
  alias Liquid.{Context, Tag, Template}

  @spec parse(%Tag{}, %Template{}) :: {%Tag{}, %Template{}}
  def parse(%Tag{} = tag, %Template{} = t), do: {tag, t}

  @doc """
  Implementation of 'ElseIf' render operations
  """
  def render(_, _, _, _), do: raise("should never get here")
end

defmodule Liquid.IfElse do
  @moduledoc """
   If is the conditional block. Exceutes a block of code only if a certain condition is true. If false executes Else block of code
   ```
     {% if user.admin %}
       Admin user!
     {% else %}
       Not admin user
     {% endif %}
      There are {% if count < 5 %} less {% else %} more {% endif %} items than you need.
  ```
  """
  alias Liquid.{Block, Condition, Context, Render, Tag, Template}

  @doc """
  Returns a regex for IF/Else expressions syntax validation
  """
  def syntax,
    do: ~r/(#{Liquid.quoted_fragment()})\s*([=!<>a-z_]+)?\s*(#{Liquid.quoted_fragment()})?/

  @doc """
  Returns a regex for IF/Else expressions and operators validation
  """
  def expressions_and_operators do
    ~r/(?:\b(?:\s?and\s?|\s?or\s?)\b|(?:\s*(?!\b(?:\s?and\s?|\s?or\s?)\b)(?:#{
      Liquid.quoted_fragment()
    }|\S+)\s*)+)/
  end

  @doc """
  Implementation of 'If/Else' parse operations
  """
  @spec parse(%Block{}, %Template{}) :: {%Block{}, %Template{}}
  def parse(%Block{} = block, %Template{} = t) do
    block = parse_conditions(block)

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
            t
          )

        {%{block | nodelist: true_block, elselist: [elseif], blank: Blank.blank?(true_block)}, t}

      {true_block, [%Tag{name: :else} | false_block]} ->
        blank? = Blank.blank?(true_block) && Blank.blank?(false_block)
        {%{block | nodelist: true_block, elselist: false_block, blank: blank?}, t}

      {_, []} ->
        {%{block | blank: Blank.blank?(block.nodelist)}, t}
    end
  end

  @doc """
  Implementation of 'If/Else' render operations
  """
  @spec render(list(), %Tag{}, %Context{}) :: {list(), %Context{}}
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

  defp parse_conditions(%Block{markup: markup} = block) do
    expressions = Regex.scan(expressions_and_operators(), markup)
    expressions = expressions |> split_conditions |> Enum.reverse()
    condition = Condition.create(expressions)
    %{block | condition: condition}
  end
end
