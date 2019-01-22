defmodule Liquid.Translators.MarkupTest do
  use ExUnit.Case
  alias Liquid.Translators.Markup

  test "transforms {:parts} tag" do
    assert Markup.literal(
             {:parts, [{:part, "company"}, {:part, "name"}, {:part, "employee"}, {:index, 0}]}
           ) == "company.name.employee[0]"

    assert Markup.literal(
             {:parts,
              [
                {:part, "company"},
                {:part, "name"},
                {:part, "employee"},
                {:index, {:variable, [parts: [part: "store", part: "state", index: 1]]}}
              ]}
           ) == "company.name.employee[store.state[1]]"
  end

  test "transforms {:variable} tag" do
    assert Markup.literal({:variable, [parts: [part: "store", part: "state", index: 1]]}) ==
             "store.state[1]"

    assert Markup.literal(
             {:variable, [parts: [part: "store", part: "state", index: 0, index: 0, index: 1]]}
           ) == "store.state[0][0][1]"

    assert Markup.literal({:variable, [parts: [part: "var", index: "a:b c", index: "paged"]]}) ==
             "var[\"a:b c\"][\"paged\"]"
  end

  test "transforms {:logical} tag" do
    assert Markup.literal({:logical, [:or, {:variable, [parts: [part: "b"]]}]}) == " or b"
  end

  test "transforms {:condition} tag" do
    assert Markup.literal({:condition, {true, :==, nil}}) == "true == null"
  end

  test "transforms {:conditions} tag" do
    assert Markup.literal(
             {:conditions,
              [variable: [parts: [part: "a"]], logical: [:or, {:variable, [parts: [part: "b"]]}]]}
           ) == "a or b"
  end

  test "transforms {:variable_name} tag" do
    assert Markup.literal({:variable_name, "cart"}) == "cart"
  end

  test "transforms {:filters} tag" do
    assert Markup.literal({:filters, [filter: ["date", {:params, [value: "%w"]}]]}) ==
             " | date: \"%w\""
  end

  test "transforms {:assignment} tag" do
    assert Markup.literal({
             :params,
             [
               assignment: [variable_name: "my_variable", value: "apples"],
               assignment: [variable_name: "my_other_variable", value: "oranges"]
             ]
           }) == ": my_variable: \"apples\", my_other_variable: \"oranges\""
  end

  test "transforms {:range} tag" do
    assert Markup.literal({:range, [start: 1, end: 10]}) == "(1..10)"
    assert Markup.literal({:range, [start: -10, end: 1]}) == "(-10..1)"
  end

  test "transforms {:reverse} tag" do
    assert Markup.literal({:reversed, []}) == " reversed"
  end
end
