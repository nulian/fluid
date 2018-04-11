defmodule Liquid.Filters.StringTest do
  use ExUnit.Case
  use Timex
  doctest Liquid.Filters.String

  alias Liquid.{Filters, Template, Variable}
  alias Liquid.Filters.{Additionals, HTML, List, Math, String}

  setup_all do
    Liquid.start()
    on_exit(fn -> Liquid.stop() end)
    :ok
  end

  test :downcase do
    assert "testing", Functions.downcase("Testing")
    assert "" == Functions.downcase(nil)
  end

  test :upcase do
    assert "TESTING" == Functions.upcase("Testing")
    assert "" == Functions.upcase(nil)
  end

  test :capitalize do
    assert "Testing" == Functions.capitalize("testing")
    assert "Testing 2 words" == Functions.capitalize("testing 2 wOrds")
    assert "" == Functions.capitalize(nil)
  end

  test :prepend do
    assert "Testing" == Functions.prepend("ing", "Test")
    assert "Test" == Functions.prepend("Test", nil)
  end

  test :truncate do
    assert "1234..." == Functions.truncate("1234567890", 7)
    assert "1234567890" == Functions.truncate("1234567890", 20)
    assert "..." == Functions.truncate("1234567890", 0)
    assert "1234567890" == Functions.truncate("1234567890")
    assert "测试..." == Functions.truncate("测试测试测试测试", 5)
    assert "1234..." == Functions.truncate("1234567890", "7")
    assert "1234!!!" == Functions.truncate("1234567890", 7, "!!!")
    assert "1234567" == Functions.truncate("1234567890", 7, "")
  end

  test :split do
    assert ["12", "34"] == Functions.split("12~34", "~")
    assert ["A? ", " ,Z"] == Functions.split("A? ~ ~ ~ ,Z", "~ ~ ~")
    assert ["A?Z"] == Functions.split("A?Z", "~")
    # Regexp works although Liquid does not support.
    # assert ["A","Z"] == Functions.split("AxZ", ~r/x/)
    assert [] == Functions.split(nil, " ")
  end

  test :truncatewords do
    assert "one two three" == Functions.truncatewords("one two three", 4)
    assert "one two..." == Functions.truncatewords("one two three", 2)
    assert "one two three" == Functions.truncatewords("one two three")

    assert "Two small (13&#8221; x 5.5&#8221; x 10&#8221; high) baskets fit inside one large basket (13&#8221;..." ==
             Functions.truncatewords(
               "Two small (13&#8221; x 5.5&#8221; x 10&#8221; high) baskets fit inside one large basket (13&#8221; x 16&#8221; x 10.5&#8221; high) with cover.",
               15
             )

    assert "测试测试测试测试" == Functions.truncatewords("测试测试测试测试", 5)
    assert "one two three" == Functions.truncatewords("one two three", "4")
  end

  test :append do
    assigns = %{"a" => "bc", "b" => "d"}
    assert_template_result("bcd", "{{ a | append: 'd'}}", assigns)
    assert_template_result("bcd", "{{ a | append: b}}", assigns)
  end

  test :prepend_template do
    assigns = %{"a" => "bc", "b" => "a"}
    assert_template_result("abc", "{{ a | prepend: 'a'}}", assigns)
    assert_template_result("abc", "{{ a | prepend: b}}", assigns)
  end

  test :replace do
    assert "Tes1ing" == Functions.replace("Testing", "t", "1")
    assert "Tesing" == Functions.replace("Testing", "t", "")
    assert "2 2 2 2" == Functions.replace("1 1 1 1", "1", 2)
    assert "2 1 1 1" == Functions.replace_first("1 1 1 1", "1", 2)
    assert_template_result("2 1 1 1", "{{ '1 1 1 1' | replace_first: '1', 2 }}")
  end

  test :remove do
    assert "   " == Functions.remove("a a a a", "a")
    assert "a a a" == Functions.remove_first("a a a a", "a ")
    assert_template_result("a a a", "{{ 'a a a a' | remove_first: 'a ' }}")
  end

  test :strip do
    assert_template_result("ab c", "{{ source | strip }}", %{"source" => " ab c  "})
    assert_template_result("ab c", "{{ source | strip }}", %{"source" => " \tab c  \n \t"})
  end

  test :lstrip do
    assert_template_result("ab c  ", "{{ source | lstrip }}", %{"source" => " ab c  "})

    assert_template_result("ab c  \n \t", "{{ source | lstrip }}", %{"source" => " \tab c  \n \t"})
  end

  test :rstrip do
    assert_template_result(" ab c", "{{ source | rstrip }}", %{"source" => " ab c  "})
    assert_template_result(" \tab c", "{{ source | rstrip }}", %{"source" => " \tab c  \n \t"})
  end

  test :pluralize do
    assert_template_result("items", "{{ 3 | pluralize: 'item', 'items' }}")
    assert_template_result("word", "{{ 1 | pluralize: 'word', 'words' }}")
  end

  test :slice do
    assert "oob" == Functions.slice("foobar", 1, 3)
    assert "oobar" == Functions.slice("foobar", 1, 1000)
    assert "" == Functions.slice("foobar", 1, 0)
    assert "o" == Functions.slice("foobar", 1, 1)
    assert "bar" == Functions.slice("foobar", 3, 3)
    assert "ar" == Functions.slice("foobar", -2, 2)
    assert "ar" == Functions.slice("foobar", -2, 1000)
    assert "r" == Functions.slice("foobar", -1)
    assert "" == Functions.slice(nil, 0)
    assert "" == Functions.slice("foobar", 100, 10)
    assert "" == Functions.slice("foobar", -100, 10)
  end

  test :slice_on_arrays do
    input = String.split("foobar", "", trim: true)
    assert ~w{o o b} == Functions.slice(input, 1, 3)
    assert ~w{o o b a r} == Functions.slice(input, 1, 1000)
    assert ~w{} == Functions.slice(input, 1, 0)
    assert ~w{o} == Functions.slice(input, 1, 1)
    assert ~w{b a r} == Functions.slice(input, 3, 3)
    assert ~w{a r} == Functions.slice(input, -2, 2)
    assert ~w{a r} == Functions.slice(input, -2, 1000)
    assert ~w{r} == Functions.slice(input, -1)
    assert ~w{} == Functions.slice(input, 100, 10)
    assert ~w{} == Functions.slice(input, -100, 10)
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