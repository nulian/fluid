defmodule Liquid.FiltersTest do
  use ExUnit.Case

  alias Liquid.{Filters, Template, Variable}

  setup_all do
    Liquid.start()
    on_exit(fn -> Liquid.stop() end)
    :ok
  end

    # Liquid.FiltersTest
  test :filters_chain_with_assigments do
    assert_template_result("abca\nb\nc", "{{ source | strip_newlines | append:source}}", %{
      "source" => "a\nb\nc"
    })
  end

  test :filters_error_wrong_in_chain do
    assert_template_result(
      "Liquid error: wrong number of arguments (2 for 1)",
      "{{ 'text' | upcase:1 | nonexisting | capitalize }}"
    )
  end

  test :filters_nonexistent_in_chain do
    assert_template_result("Text", "{{ 'text' | upcase | nonexistent | capitalize }}")
  end

  test :filter_and_tag do
    assert_template_result(
      "V 1: 2: 1: 4: 5: 0 | 011245",
      "V {{ var2 }}{% capture var2 %}{{ '1: 2: 1: 4: 5' }}: 0{% endcapture %}{{ var2 }} | {{ var2 | split: ': ' | sort }}"
    )
  end

  test :pipes_in_string_arguments do
    assert_template_result("foobar", "{{ 'foo|bar' | remove: '|' }}")
  end

  test :parse_input do
    [name | filters] = "'foofoo' | replace:'foo','bar'" |> Variable.parse()

    assert "'foofoo'" == name
    assert [[:replace, ["'foo'", "'bar'"]]] == filters
  end

  test :filter_parsed do
    name = "'foofoo'"
    filters = [[:replace, ["'foo'", "'bar'"]]]
    assert "'barbar'" == Filters.filter(filters, name)
  end

  # Liquid.FiltersTest

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
