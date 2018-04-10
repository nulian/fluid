defmodule Liquid.Condition do
  @moduledoc "Handle liquid conditional operators and its variables (left and right side of conditionals)"

  defstruct left: nil, operator: nil, right: nil, child_operator: nil, child_condition: nil

  alias Liquid.{Condition, Context, Variable}

  @doc "Create a list of conditional and vars including positioning of each element"
  def create([h | t]) do
    head = create(h)
    create(head, t)
  end

  def create(<<left::binary>>) do
    left = Variable.create(left)
    %Condition{left: left}
  end

  def create({<<left::binary>>, operator, <<right::binary>>}) do
    create({left |> Variable.create(), operator, right |> Variable.create()})
  end

  def create({%Variable{} = left, operator, <<right::binary>>}) do
    create({left, operator, right |> Variable.create()})
  end

  def create({<<left::binary>>, operator, %Variable{} = right}) do
    create({left |> Variable.create(), operator, right})
  end

  def create({%Variable{} = left, operator, %Variable{} = right}) do
    operator = String.to_atom(operator)
    %Condition{left: left, operator: operator, right: right}
  end

  def create(condition, []), do: condition

  def create(condition, [join, right | _]) when join == "and" or join == "or" do
    right = create(right)
    join = join |> String.trim() |> String.to_atom()
    join(join, condition, right)
  end

  def join(operator, condition, {_, _, _} = right), do: join(operator, condition, create(right))

  def join(operator, condition, %Condition{} = right) do
    %{right | child_condition: condition, child_operator: operator}
  end

  @doc "Evaluates conditions due a given context"
  def evaluate(%Condition{} = condition), do: evaluate(condition, %Context{})

  def evaluate(%Condition{left: left, right: nil} = condition, %Context{} = context) do
    {current, context} = Variable.lookup(left, context)
    eval_child(current, condition.child_operator, condition.child_condition, context)
  end

  def evaluate(
        %Condition{left: left, right: right, operator: operator} = condition,
        %Context{} = context
      ) do
    {left, _} = Variable.lookup(left, context)
    {right, _} = Variable.lookup(right, context)
    current = eval_operator(left, operator, right)
    eval_child(current, condition.child_operator, condition.child_condition, context)
  end

  defp eval_child(current, nil, nil, _), do: current

  defp eval_child(current, :and, condition, context) do
    current and evaluate(condition, context)
  end

  defp eval_child(current, :or, condition, context) do
    current or evaluate(condition, context)
  end

  defp eval_operator(left, operator, right)
       when (is_nil(left) or is_nil(right)) and not (is_nil(left) and is_nil(right)) and
              operator in [:>=, :>, :<, :<=],
       do: false

  defp eval_operator([] = left, :==, :empty?), do: Enum.empty?(left)
  defp eval_operator([] = left, :<>, :empty?), do: eval_operator(left, :!==, :empty?)
  defp eval_operator([] = left, :!=, :empty?), do: !Enum.empty?(left)

  defp eval_operator(left, operator, right) do
    case operator do
      :== -> left == right
      :>= -> left >= right
      :> -> left > right
      :<= -> left <= right
      :< -> left < right
      :!= -> left != right
      :<> -> left != right
      :contains -> contains(left, right)
    end
  end

  defp contains(nil, _), do: false
  defp contains(_, nil), do: false

  defp contains(<<left::binary>>, <<right::binary>>),
    do: contains(left |> to_charlist, right |> to_charlist)

  defp contains(left, <<right::binary>>) when is_list(left),
    do: contains(left, right |> to_charlist)

  defp contains(<<left::binary>>, right) when is_list(right),
    do: contains(left |> to_charlist, right)

  defp contains(left, right) when is_list(left) and not is_list(right),
    do: contains(left, [right])

  defp contains(left, right) when is_list(right) and is_list(left),
    do: :string.rstr(left, right) > 0
end
