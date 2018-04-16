Code.require_file("../../test_helper.exs", __ENV__.file)

defmodule Liquid.RawTest do
  use ExUnit.Case

  alias Liquid.Template, as: Template

  setup_all do
    Liquid.start()
    :ok
  end

  test :test_tag_in_raw do
    assert_template_result(
      "{% comment %} test {% endcomment %}",
      "{% raw %}{% comment %} test {% endcomment %}{% endraw %}"
    )
  end

  test :test_output_in_raw do
    assert_template_result("{{ test }}", "{% raw %}{{ test }}{% endraw %}")
  end

  test :test_open_tag_in_raw do
    assert_template_result(" Foobar {% invalid ", "{% raw %} Foobar {% invalid {% endraw %}")
    assert_template_result(" Foobar invalid %} ", "{% raw %} Foobar invalid %} {% endraw %}")
    assert_template_result(" Foobar {{ invalid ", "{% raw %} Foobar {{ invalid {% endraw %}")
    assert_template_result(" Foobar invalid }} ", "{% raw %} Foobar invalid }} {% endraw %}")

    assert_template_result(
      " Foobar {% invalid {% {% endraw ",
      "{% raw %} Foobar {% invalid {% {% endraw {% endraw %}"
    )

    assert_template_result(" Foobar {% {% {% ", "{% raw %} Foobar {% {% {% {% endraw %}")

    assert_template_result(
      " test {% raw %} {% endraw %}",
      "{% raw %} test {% raw %} {% {% endraw %}endraw %}"
    )

    assert_template_result(
      " Foobar {{ invalid 1",
      "{% raw %} Foobar {{ invalid {% endraw %}{{ 1 }}"
    )
  end

  # test :test_invalid_raw do
  #   assert_match_syntax_error ~r/tag was never closed/, "{% raw %} foo"
  #   assert_match_syntax_error ~r/Valid syntax/, "{% raw } foo {% endraw %}"
  #   assert_match_syntax_error ~r/Valid syntax/, "{% raw } foo %}{% endraw %}"
  # end

  defp assert_template_result(expected, markup) do
    assert_result(expected, markup, %{})
  end

  defp assert_result(expected, markup, assigns) do
    template = Template.parse(markup)

    {:ok, result, _} = Template.render(template, assigns)
    assert result == expected
  end
end
