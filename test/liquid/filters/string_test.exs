defmodule Liquid.Filters.StringTest do
  use ExUnit.Case
  doctest Liquid.Filters.String

  alias Liquid.Template
  alias Liquid.Filters.String, as: FString

  setup_all do
    Liquid.start()
    on_exit(fn -> Liquid.stop() end)
    :ok
  end

  test :downcase do
    assert "testing", FString.downcase("Testing")
    assert "" == FString.downcase(nil)
  end

  test :upcase do
    assert "TESTING" == FString.upcase("Testing")
    assert "" == FString.upcase(nil)
  end

  test :capitalize do
    assert "Testing" == FString.capitalize("testing")
    assert "Testing 2 words" == FString.capitalize("testing 2 wOrds")
    assert "" == FString.capitalize(nil)
  end

  test :prepend do
    assert "Testing" == FString.prepend("ing", "Test")
    assert "Test" == FString.prepend("Test", nil)
  end

  test :truncate do
    assert "1234..." == FString.truncate("1234567890", 7)
    assert "1234567890" == FString.truncate("1234567890", 20)
    assert "..." == FString.truncate("1234567890", 0)
    assert "1234567890" == FString.truncate("1234567890")
    assert "测试..." == FString.truncate("测试测试测试测试", 5)
    assert "1234..." == FString.truncate("1234567890", "7")
    assert "1234!!!" == FString.truncate("1234567890", 7, "!!!")
    assert "1234567" == FString.truncate("1234567890", 7, "")
  end

  test :split do
    assert ["12", "34"] == FString.split("12~34", "~")
    assert ["A? ", " ,Z"] == FString.split("A? ~ ~ ~ ,Z", "~ ~ ~")
    assert ["A?Z"] == FString.split("A?Z", "~")
    # Regexp works although Liquid does not support.
    # assert ["A","Z"] == FString.split("AxZ", ~r/x/)
    assert [] == FString.split(nil, " ")
  end

  test :truncatewords do
    assert "one two three" == FString.truncatewords("one two three", 4)
    assert "one two..." == FString.truncatewords("one two three", 2)
    assert "one two three" == FString.truncatewords("one two three")

    assert "Two small (13&#8221; x 5.5&#8221; x 10&#8221; high) baskets fit inside one large basket (13&#8221;..." ==
             FString.truncatewords(
               "Two small (13&#8221; x 5.5&#8221; x 10&#8221; high) baskets fit inside one large basket (13&#8221; x 16&#8221; x 10.5&#8221; high) with cover.",
               15
             )

    assert "测试测试测试测试" == FString.truncatewords("测试测试测试测试", 5)
    assert "one two three" == FString.truncatewords("one two three", "4")
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
    assert "Tes1ing" == FString.replace("Testing", "t", "1")
    assert "Tesing" == FString.replace("Testing", "t", "")
    assert "2 2 2 2" == FString.replace("1 1 1 1", "1", 2)
    assert "2 1 1 1" == FString.replace_first("1 1 1 1", "1", 2)
    assert_template_result("2 1 1 1", "{{ '1 1 1 1' | replace_first: '1', 2 }}")
  end

  test :remove do
    assert "   " == FString.remove("a a a a", "a")
    assert "a a a" == FString.remove_first("a a a a", "a ")
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
    assert "oob" == FString.slice("foobar", 1, 3)
    assert "oobar" == FString.slice("foobar", 1, 1000)
    assert "" == FString.slice("foobar", 1, 0)
    assert "o" == FString.slice("foobar", 1, 1)
    assert "bar" == FString.slice("foobar", 3, 3)
    assert "ar" == FString.slice("foobar", -2, 2)
    assert "ar" == FString.slice("foobar", -2, 1000)
    assert "r" == FString.slice("foobar", -1)
    assert "" == FString.slice(nil, 0)
    assert "" == FString.slice("foobar", 100, 10)
    assert "" == FString.slice("foobar", -100, 10)
  end

  test :slice_on_arrays do
    input = String.split("foobar", "", trim: true)
    assert ~w{o o b} == FString.slice(input, 1, 3)
    assert ~w{o o b a r} == FString.slice(input, 1, 1000)
    assert ~w{} == FString.slice(input, 1, 0)
    assert ~w{o} == FString.slice(input, 1, 1)
    assert ~w{b a r} == FString.slice(input, 3, 3)
    assert ~w{a r} == FString.slice(input, -2, 2)
    assert ~w{a r} == FString.slice(input, -2, 1000)
    assert ~w{r} == FString.slice(input, -1)
    assert ~w{} == FString.slice(input, 100, 10)
    assert ~w{} == FString.slice(input, -100, 10)
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
