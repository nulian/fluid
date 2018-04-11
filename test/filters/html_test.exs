defmodule Liquid.Filters.HTMLTest do
  use ExUnit.Case
  use Timex
  doctest Liquid.Filters.HTML

  alias Liquid.{Filters, Template, Variable}
  alias Liquid.Filters.{Additionals, HTML, List, Math, String}

  setup_all do
    Liquid.start()
    on_exit(fn -> Liquid.stop() end)
    :ok
  end

  test :escape do
    assert "&lt;strong&gt;" == Functions.escape("<strong>")
    assert "&lt;strong&gt;" == Functions.h("<strong>")
  end

  test :escape_once do
    assert "&lt;strong&gt;Hulk&lt;/strong&gt;" ==
             Functions.escape_once("&lt;strong&gt;Hulk</strong>")
  end

  test :url_encode do
    assert "foo%2B1%40example.com" == Functions.url_encode("foo+1@example.com")
    assert nil == Functions.url_encode(nil)
  end

  test :strip_html do
    assert "test" == Functions.strip_html("<div>test</div>")
    assert "test" == Functions.strip_html(~s{<div id="test">test</div>})

    assert "" ==
             Functions.strip_html(
               ~S{<script type="text/javascript">document.write("some stuff");</script>}
             )

    assert "" == Functions.strip_html(~S{<style type="text/css">foo bar</style>})
    assert "test" == Functions.strip_html(~S{<div\nclass="multiline">test</div>})
    assert "test" == Functions.strip_html(~S{<!-- foo bar \n test -->test})
    assert "" == Functions.strip_html(nil)
  end

  test :strip_newlines do
    assert_template_result("abc", "{{ source | strip_newlines }}", %{"source" => "a\nb\nc"})
    assert_template_result("abc", "{{ source | strip_newlines }}", %{"source" => "a\r\nb\nc"})
    assert_template_result("abc", "{{ source | strip_newlines }}", %{"source" => "a\r\nb\nc\r\n"})
  end

  test :newlines_to_br do
    assert_template_result("a<br />\nb<br />\nc", "{{ source | newline_to_br }}", %{
      "source" => "a\nb\nc"
    })
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