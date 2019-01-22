defmodule Liquid.TokenizerTest do
  use ExUnit.Case

  alias Liquid.Tokenizer

  test "empty string" do
    assert Tokenizer.tokenize("") == {"", ""}
  end

  test "white string" do
    assert Tokenizer.tokenize("    ") == {"    ", ""}
  end

  test "starting tag" do
    assert Tokenizer.tokenize("{% hello %}") == {"", "{% hello %}"}
  end

  test "starting variable" do
    assert Tokenizer.tokenize("{{ hello }}") == {"", "{{ hello }}"}
  end

  test "tag starting with literal" do
    assert Tokenizer.tokenize("world {% hello %}") == {"world ", "{% hello %}"}
  end

  test "variable starting with literal" do
    assert Tokenizer.tokenize("world {{ hello }}") == {"world ", "{{ hello }}"}
  end

  test "literal inside block" do
    assert Tokenizer.tokenize("{% hello %} Hello {% endhello %}") ==
             {"", "{% hello %} Hello {% endhello %}"}
  end
end
