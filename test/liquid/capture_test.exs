Code.require_file("../../test_helper.exs", __ENV__.file)

defmodule Liquid.CaptureTest do
  use ExUnit.Case

  setup do
    start_supervised!({Liquid.Process, [name: :liquid]})
    :ok
  end

  test :test_captures_block_content_in_variable do
    assert_template_result(
      "test string",
      "{% capture 'var' %}test string{% endcapture %}{{var}}",
      %{}
    )
  end

  test :test_capture_with_hyphen_in_variable_name do
    template_source = """
    {% capture this-thing %}Print this-thing{% endcapture %}
    {{ this-thing }}
    """

    template = Liquid.parse_template(:liquid, template_source)
    {:ok, result, _} = Liquid.render_template(:liquid, template)
    assert "Print this-thing" == result |> String.trim()
  end

  test :test_capture_to_variable_from_outer_scope_if_existing do
    template_source = """
    {% assign var = '' %}
    {% if true %}
    {% capture var %}first-block-string{% endcapture %}
    {% endif %}
    {% if true %}
    {% capture var %}test-string{% endcapture %}
    {% endif %}
    {{var}}
    """

    template = Liquid.parse_template(:liquid, template_source)
    {:ok, result, _} = Liquid.render_template(:liquid, template)
    assert "test-string" == Regex.replace(~r/\s/, result, "")
  end

  test :test_assigning_from_capture do
    template_source = """
    {% assign first = '' %}
    {% assign second = '' %}
    {% for number in (1..3) %}
    {% capture first %}{{number}}{% endcapture %}
    {% assign second = first %}
    {% endfor %}
    {{ first }}-{{ second }}
    """

    template = Liquid.parse_template(:liquid, template_source)
    {:ok, result, _} = Liquid.render_template(:liquid, template)
    assert "3-3" == Regex.replace(~r/\n/, result, "")
  end

  defp assert_template_result(expected, markup, assigns) do
    assert_result(expected, markup, assigns)
  end

  defp assert_result(expected, markup, assigns) do
    template = Liquid.parse_template(:liquid, markup)
    {:ok, result, _} = Liquid.render_template(:liquid, template, assigns)
    assert result == expected
  end
end
