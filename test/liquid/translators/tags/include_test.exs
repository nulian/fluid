defmodule Liquid.Translators.Tags.IncludeTest do
  use ExUnit.Case
  import Liquid.Helpers
  alias Liquid.FileSystem

  defmodule TestFileSystem do
    def read_template_file(_root, template_path, _context) do
      case template_path do
        "product" ->
          {:ok, "Product: {{ product.title }} "}

        "locale_variables" ->
          {:ok, "Locale: {{echo1}} {{echo2}}"}

        "variant" ->
          {:ok, "Variant: {{ variant.title }}"}

        "nested_template" ->
          {:ok, "{% include 'header' %} {% include 'body' %} {% include 'footer' %}"}

        "body" ->
          {:ok, "body {% include 'body_detail' %}"}

        "nested_product_template" ->
          {:ok, "Product: {{ nested_product_template.title }} {%include 'details'%} "}

        "recursively_nested_template" ->
          {:ok, "-{% include 'recursively_nested_template' %}"}

        "pick_a_source" ->
          {:ok, "from TestFileSystem"}

        _ ->
          {:ok, template_path}
      end
    end
  end

  setup_all do
    Liquid.start()
    FileSystem.register(TestFileSystem)
    on_exit(fn -> Liquid.stop() end)
    :ok
  end

  test "include translate new AST to old AST" do
    [
      {"{% include 'product' %}", %{}},
      {"{% include 'product' with products[0] %}",
       %{"products" => [%{"title" => "Draft 151cm"}, %{"title" => "Element 155cm"}]}},
      {"{% include 'product' for products %}",
       %{"products" => [%{"title" => "Draft 151cm"}, %{"title" => "Element 155cm"}]}},
      {"{% include 'locale_variables' echo1: 'test123' %}", %{}},
      {"{% include 'locale_variables' echo1: 'test123', echo2: 'test321' %}", %{}},
      {"{% include 'locale_variables' echo1: echo1, echo2: more_echos.echo2 %}",
       %{"echo1" => "test123", "more_echos" => %{"echo2" => "test321"}}},
      {"{% include 'body' %}", %{}},
      {"{% include 'nested_template' %}", %{}},
      {"{% include 'nested_product_template' with product %}",
       %{"product" => %{"title" => "Draft 151cm"}}},
      {"{% include 'nested_product_template' for products %}",
       %{"products" => [%{"title" => "Draft 151cm"}, %{"title" => "Element 155cm"}]}},
      {"{% include 'cart' %}", %{"cart" => %{"title" => "Draft 151cm"}}}
    ]
    |> Enum.each(fn {markup, params} ->
      test_ast_translation(markup, params)
    end)
  end
end
