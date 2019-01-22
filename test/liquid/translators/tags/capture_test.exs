defmodule Liquid.Translators.Tags.CaptureTests do
  use ExUnit.Case
  import Liquid.Helpers

  test "capture translate new AST to old AST" do
    [
      "{% capture 'var' %}test string{% endcapture %}{{var}}",
      "{% capture this-thing %}Print this-thing{% endcapture %} {{ this-thing }}",
      """
        {% assign var = '' %}
        {% if true %}
        {% capture var %}first-block-string{% endcapture %}
        {% endif %}
        {% if true %}
        {% capture var %}test-string{% endcapture %}
        {% endif %}
        {{var}}
      """,
      """
        {% assign first = '' %}
        {% assign second = '' %}
        {% for number in (1..3) %}
        {% capture first %}{{number}}{% endcapture %}
        {% assign second = first %}
        {% endfor %}
        {{ first }}-{{ second }}
      """
    ]
    |> Enum.each(fn tag ->
      test_ast_translation(tag)
    end)
  end
end
