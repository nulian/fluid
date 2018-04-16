Code.require_file("../../test_helper.exs", __ENV__.file)

defmodule Liquid.GlobalFilterTest do
  use ExUnit.Case, async: false
  alias Liquid.Template

  defmodule MyFilter do
    def counting_sheeps(input) when is_binary(input), do: input <> " One, two, thr.. z-zz.."
    def counting_bees(input) when is_binary(input), do: input <> " One, tw.. Ouch!"
  end

  setup_all do
    Application.put_env(:liquid, :global_filter, &MyFilter.counting_sheeps/1)
    Liquid.start()
    on_exit(fn -> Liquid.stop(Application.delete_env(:liquid, :global_filter)) end)
    :ok
  end

  test "env default filter applied" do
    assert_template_result("Initial One, two, thr.. z-zz..", "{{ 'initial' | capitalize }}")
  end

  test "preset filter overrides default applied" do
    assert_template_result("Initial One, tw.. Ouch!", "{{ 'initial' | capitalize }}", %{
      global_filter: &MyFilter.counting_bees/1
    })
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
