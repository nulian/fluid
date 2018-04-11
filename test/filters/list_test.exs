defmodule Liquid.Filters.ListTest do
  use ExUnit.Case
  use Timex
  doctest Liquid.Filters.List

  alias Liquid.{Filters, Template, Variable}
  alias Liquid.Filters.{Additionals, HTML, List, Math, String}

  setup_all do
    Liquid.start()
    on_exit(fn -> Liquid.stop() end)
    :ok
  end

  test :join do
    assert "1 2 3 4" == Functions.join([1, 2, 3, 4])
    assert "1 - 2 - 3 - 4" == Functions.join([1, 2, 3, 4], " - ")

    assert_template_result(
      "1, 1, 2, 4, 5",
      ~s({{"1: 2: 1: 4: 5" | split: ": " | sort | join: ", " }})
    )
  end

  test :sort do
    assert [1, 2, 3, 4] == Functions.sort([4, 3, 2, 1])

    assert [%{"a" => 1}, %{"a" => 2}, %{"a" => 3}, %{"a" => 4}] ==
             Functions.sort([%{"a" => 4}, %{"a" => 3}, %{"a" => 1}, %{"a" => 2}], "a")

    assert [%{"a" => 1, "b" => 1}, %{"a" => 3, "b" => 2}, %{"a" => 2, "b" => 3}] ==
             Functions.sort(
               [%{"a" => 3, "b" => 2}, %{"a" => 1, "b" => 1}, %{"a" => 2, "b" => 3}],
               "b"
             )

    # Elixir keyword list support
    assert [a: 1, a: 2, a: 3, a: 4] == Functions.sort([{:a, 4}, {:a, 3}, {:a, 1}, {:a, 2}], "a")
  end

  test :sort_integrity do
    assert_template_result("11245", ~s({{"1: 2: 1: 4: 5" | split: ": " | sort }}))
  end

  test :legacy_sort_hash do
    assert Map.to_list(%{a: 1, b: 2}) == Functions.sort(a: 1, b: 2)
  end

  test :numerical_vs_lexicographical_sort do
    assert [2, 10] == Functions.sort([10, 2])
    assert [{"a", 2}, {"a", 10}] == Functions.sort([{"a", 10}, {"a", 2}], "a")
    assert ["10", "2"] == Functions.sort(["10", "2"])
    assert [{"a", "10"}, {"a", "2"}] == Functions.sort([{"a", "10"}, {"a", "2"}], "a")
  end

  test :uniq do
    assert [1, 3, 2, 4] == Functions.uniq([1, 1, 3, 2, 3, 1, 4, 3, 2, 1])

    assert [{"a", 1}, {"a", 3}, {"a", 2}] ==
             Functions.uniq([{"a", 1}, {"a", 3}, {"a", 1}, {"a", 2}], "a")

    # testdrop = TestDrop.new
    # assert [testdrop] == Functions.uniq([testdrop, TestDrop.new], "test")
  end

  test :reverse do
    assert [4, 3, 2, 1] == Functions.reverse([1, 2, 3, 4])
  end

  test :legacy_reverse_hash do
    assert [Map.to_list(%{a: 1, b: 2})] == Functions.reverse(a: 1, b: 2)
  end

  test :map do
    assert [1, 2, 3, 4] ==
             Functions.map([%{"a" => 1}, %{"a" => 2}, %{"a" => 3}, %{"a" => 4}], "a")

    assert_template_result("abc", "{{ ary | map:'foo' | map:'bar' }}", %{
      "ary" => [
        %{"foo" => %{"bar" => "a"}},
        %{"foo" => %{"bar" => "b"}},
        %{"foo" => %{"bar" => "c"}}
      ]
    })
  end

  test :map_doesnt_call_arbitrary_stuff do
    assert_template_result("", ~s[{{ "foo" | map: "__id__" }}])
    assert_template_result("", ~s[{{ "foo" | map: "inspect" }}])
  end

  test :first_last do
    assert 1 == Functions.first([1, 2, 3])
    assert 3 == Functions.last([1, 2, 3])
    assert nil == Functions.first([])
    assert nil == Functions.last([])
  end

  test :size do
    assert 3 == Functions.size([1, 2, 3])
    assert 0 == Functions.size([])
    assert 0 == Functions.size(nil)

    # for strings
    assert 3 == Functions.size("foo")
    assert 0 == Functions.size("")
  end

  #Helper Test Builder Functions
  defp assert_template_result(expected, markup, assigns \\ %{})

  defp assert_template_result(expected, markup, assigns) do
    assert_result(expected, markup, assigns)
  end

  defp assert_result(expected, markup, assigns) do
    template = Template.parse(markup)

    with {:ok, result, _} <- Template.render(template, assigns) do
      assert result == expected
    else
      {:error, message, _} ->
        assert message == expected
    end
  end

end