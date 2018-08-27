defmodule Liquid.Filters.ListTest do
  use ExUnit.Case
  use Timex
  doctest Liquid.Filters.List

  alias Liquid.Template
  alias Liquid.Filters.List

  setup_all do
    Liquid.start()
    on_exit(fn -> Liquid.stop() end)
    :ok
  end

  test :join do
    assert "1 2 3 4" == List.join([1, 2, 3, 4])
    assert "1 - 2 - 3 - 4" == List.join([1, 2, 3, 4], " - ")

    assert_template_result(
      "1, 1, 2, 4, 5",
      ~s({{"1: 2: 1: 4: 5" | split: ": " | sort | join: ", " }})
    )
  end

  test :sort do
    assert [1, 2, 3, 4] == List.sort([4, 3, 2, 1])

    assert [%{"a" => 1}, %{"a" => 2}, %{"a" => 3}, %{"a" => 4}] ==
             List.sort([%{"a" => 4}, %{"a" => 3}, %{"a" => 1}, %{"a" => 2}], "a")

    assert [%{"a" => 1, "b" => 1}, %{"a" => 3, "b" => 2}, %{"a" => 2, "b" => 3}] ==
             List.sort(
               [%{"a" => 3, "b" => 2}, %{"a" => 1, "b" => 1}, %{"a" => 2, "b" => 3}],
               "b"
             )

    # Elixir keyword list support
    assert [a: 1, a: 2, a: 3, a: 4] == List.sort([{:a, 4}, {:a, 3}, {:a, 1}, {:a, 2}], "a")
  end

  test :sort_integrity do
    assert_template_result("11245", ~s({{"1: 2: 1: 4: 5" | split: ": " | sort }}))
  end

  test :legacy_sort_hash do
    assert Map.to_list(%{a: 1, b: 2}) == List.sort(a: 1, b: 2)
  end

  test :numerical_vs_lexicographical_sort do
    assert [2, 10] == List.sort([10, 2])
    assert [{"a", 2}, {"a", 10}] == List.sort([{"a", 10}, {"a", 2}], "a")
    assert ["10", "2"] == List.sort(["10", "2"])
    assert [{"a", "10"}, {"a", "2"}] == List.sort([{"a", "10"}, {"a", "2"}], "a")
  end

  test :uniq do
    assert [1, 3, 2, 4] == List.uniq([1, 1, 3, 2, 3, 1, 4, 3, 2, 1])

    assert [{"a", 1}, {"a", 3}, {"a", 2}] ==
             List.uniq([{"a", 1}, {"a", 3}, {"a", 1}, {"a", 2}], "a")

    # testdrop = TestDrop.new
    # assert [testdrop] == List.uniq([testdrop, TestDrop.new], "test")
  end

  test :reverse do
    assert [4, 3, 2, 1] == List.reverse([1, 2, 3, 4])
  end

  test :legacy_reverse_hash do
    assert [Map.to_list(%{a: 1, b: 2})] == List.reverse(a: 1, b: 2)
  end

  test :map do
    assert [1, 2, 3, 4] ==
             List.map([%{"a" => 1}, %{"a" => 2}, %{"a" => 3}, %{"a" => 4}], "a")

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
    assert 1 == List.first([1, 2, 3])
    assert 3 == List.last([1, 2, 3])
    assert nil == List.first([])
    assert nil == List.last([])
  end

  test :size do
    assert 3 == List.size([1, 2, 3])
    assert 0 == List.size([])
    assert 0 == List.size(nil)

    # for strings
    assert 3 == List.size("foo")
    assert 0 == List.size("")
  end

  defp assert_template_result(expected, markup, assigns \\ %{}) do
    template = Template.parse(markup)

    with {:ok, result, _} <- Template.render(template, assigns) do
      assert result == expected
    else
      {:error, message, _} ->
        assert message == expected
    end
  end

end
