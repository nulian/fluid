Code.require_file("../../test_helper.exs", __ENV__.file)

defmodule Liquid.CustomFilterTest do
  use ExUnit.Case
  alias Liquid.Template

  defmodule MyFilter do
    def meaning_of_life(_, _), do: 42
  end

  defmodule MyFilterTwo do
    def meaning_of_life(_, _), do: 40
    def not_meaning_of_life(_, _), do: 2
  end

  defmodule MyFilterThree do
    def stuff(_, context) do
      context.assigns.test
    end
  end

  setup_all do
    Application.put_env(:liquid, :extra_filter_modules, [MyFilter, MyFilterTwo, MyFilterThree])
    Liquid.start()
    on_exit(fn -> Liquid.stop() end)
    :ok
  end

  test "custom filter uses the first passed filter" do
    assert_template_result("42", "{{ 'whatever' | meaning_of_life }}")
  end

  test :nonexistent_in_custom_chain do
    assert_template_result(
      "2",
      "{{ 'text' | capitalize | not_meaning_of_life | minus_nonexistent: 1 }}"
    )
  end

  test :custom_filter_in_chain do
    assert_template_result(
      "41",
      "{{ 'text' | upcase | nonexistent | meaning_of_life | minus: 1 }}"
    )
  end

  test "custom filter can use context" do
    assert_template_result("100", "{{ 'text' | stuff }}", %{test: 100})
  end

  defp assert_template_result(expected, markup, assigns \\ %{}) do
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
