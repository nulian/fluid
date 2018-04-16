Code.require_file("../../test_helper.exs", __ENV__.file)

defmodule ConditionTest do
  use ExUnit.Case

  alias Liquid.Condition, as: Condition

  test :basic_condition do
    assert_evaluates_false("1", "==", "2")
    assert_evaluates_true("1", "==", "1")
  end

  test :default_operators_evaluate_true do
    assert_evaluates_true("1", "==", "1")
    assert_evaluates_true("1", "!=", "2")
    assert_evaluates_true("1", "<>", "2")
    assert_evaluates_true("1", "<", "2")
    assert_evaluates_true("2", ">", "1")
    assert_evaluates_true("1", ">=", "1")
    assert_evaluates_true("2", ">=", "1")
    assert_evaluates_true("1", "<=", "2")
    assert_evaluates_true("1", "<=", "1")
    # negative numbers
    assert_evaluates_true("1", ">", "-1")
    assert_evaluates_true("-1", "<", "1")
    assert_evaluates_true("1.0", ">", "-1.0")
    assert_evaluates_true("-1.0", "<", "1.0")
  end

  test :default_operators_evalute_false do
    assert_evaluates_false("1", "==", "2")
    assert_evaluates_false("1", "!=", "1")
    assert_evaluates_false("1", "<>", "1")
    assert_evaluates_false("1", "<", "0")
    assert_evaluates_false("2", ">", "4")
    assert_evaluates_false("1", ">=", "3")
    assert_evaluates_false("2", ">=", "4")
    assert_evaluates_false("1", "<=", "0")
    assert_evaluates_false("1", "<=", "0")
  end

  test :contains_works_on_strings do
    assert_evaluates_true("'bob'", "contains", "'o'")
    assert_evaluates_true("'bob'", "contains", "'b'")
    assert_evaluates_true("'bob'", "contains", "'bo'")
    assert_evaluates_true("'bob'", "contains", "'ob'")
    assert_evaluates_true("'bob'", "contains", "'bob'")

    assert_evaluates_false("'bob'", "contains", "'bob2'")
    assert_evaluates_false("'bob'", "contains", "'a'")
    assert_evaluates_false("'bob'", "contains", "'---'")
  end

  test :contains_works_on_arrays do
    assigns = %{"array" => [1, 2, 3, 4, 5]}

    assert_evaluates_false("array", "contains", "0", assigns)
    assert_evaluates_true("array", "contains", "1", assigns)
    assert_evaluates_true("array", "contains", "2", assigns)
    assert_evaluates_true("array", "contains", "3", assigns)
    assert_evaluates_true("array", "contains", "4", assigns)
    assert_evaluates_true("array", "contains", "5", assigns)
    assert_evaluates_false("array", "contains", "6", assigns)
    assert_evaluates_false("array", "contains", "\"1\"", assigns)
  end

  test :contains_returns_false_for_nil_operands do
    assert_evaluates_false("not_assigned", "contains", "0")
    assert_evaluates_false("0", "contains", "not_assigned")
  end

  test :or_condition do
    condition = Condition.create({"1", "==", "2"})
    assert false == Condition.evaluate(condition)
    condition = Condition.join(:or, condition, {"2", "==", "2"})
    assert true == Condition.evaluate(condition)
    condition = Condition.join(:or, condition, {"2", "==", "1"})
    assert true == Condition.evaluate(condition)
  end

  test :and_condition do
    condition = Condition.create({"2", "==", "1"})
    assert false == Condition.evaluate(condition)
    condition = Condition.join(:and, condition, {"2", "==", "2"})
    assert false == Condition.evaluate(condition)

    condition = Condition.create({"2", "==", "2"})
    assert true == Condition.evaluate(condition)
    condition = Condition.join(:and, condition, {"2", "==", "1"})
    assert false == Condition.evaluate(condition)
  end

  # # test :should_allow_custom_proc_operator do
  # #   Condition.operators['starts_with'] = Proc.new { |cond, left, right| left =~ ~r{^#{right}} }

  # #   assert_evaluates_true "'bob'",   'starts_with', "'b'"
  # #   assert_evaluates_false "'bob'",  'starts_with', "'o'"

  # #   ensure
  # #     Condition.operators.delete 'starts_with'
  # # end

  test :left_or_right_may_contain_operators do
    assign = "gnomeslab-and-or-liquid"
    assigns = %{"one" => assign, "another" => assign}
    assert_evaluates_true("one", "==", "another", assigns)
  end

  defp assert_evaluates_true(left, op, right, assigns \\ %{}) do
    condition = Condition.create({left, op, right})
    context = %Liquid.Context{assigns: assigns, presets: %{}}
    evaled = Condition.evaluate(condition, context)
    unless evaled, do: IO.puts("Evaluated false: #{left} #{op} #{right}")
    assert evaled
  end

  defp assert_evaluates_false(left, op, right, assigns \\ %{}) do
    condition = Condition.create({left, op, right})
    context = %Liquid.Context{assigns: assigns, presets: %{}}
    evaled = Condition.evaluate(condition, context)
    unless !evaled, do: IO.puts("Evaluated true: #{left} #{op} #{right}")
    assert !evaled
  end
end
