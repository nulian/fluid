Code.require_file("../../test_helper.exs", __ENV__.file)

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

defmodule OtherFileSystem do
  def read_template_file(_root, _template_path, _context) do
    {:ok, "from OtherFileSystem"}
  end
end

defmodule IncludeTagTest do
  use ExUnit.Case

  alias Liquid.Template, as: Template
  alias Liquid.Context, as: Context

  setup_all do
    Liquid.start()
    Liquid.FileSystem.register(TestFileSystem)
    on_exit(fn -> Liquid.stop() end)
    :ok
  end

  test :include_tag_looks_for_file_system_in_registers_first do
    assert_result("from OtherFileSystem", "{% include 'pick_a_source' %}", %Context{
      registers: %{file_system: {OtherFileSystem, ""}}
    })
  end

  test :include_tag_with do
    assert_result("Product: Draft 151cm ", "{% include 'product' with products[0] %}", %{
      "products" => [%{"title" => "Draft 151cm"}, %{"title" => "Element 155cm"}]
    })
  end

  test :include_tag_with_default_name do
    assert_result("Product: Draft 151cm ", "{% include 'product' %}", %{
      "product" => %{"title" => "Draft 151cm"}
    })
  end

  test :include_tag_for do
    assert_result(
      "Product: Draft 151cm Product: Element 155cm ",
      "{% include 'product' for products %}",
      %{"products" => [%{"title" => "Draft 151cm"}, %{"title" => "Element 155cm"}]}
    )
  end

  test :include_tag_with_local_variables do
    assert_result("Locale: test123 ", "{% include 'locale_variables', echo1: 'test123' %}")
  end

  test :include_tag_with_multiple_local_variables do
    assert_result(
      "Locale: test123 test321",
      "{% include 'locale_variables' echo1: 'test123', echo2: 'test321' %}"
    )
  end

  test :include_tag_with_multiple_local_variables_from_context do
    assert_result(
      "Locale: test123 test321",
      "{% include 'locale_variables' echo1: echo1, echo2: more_echos.echo2 %}",
      %{"echo1" => "test123", "more_echos" => %{"echo2" => "test321"}}
    )
  end

  test :nested_include_tag do
    assert_result("body body_detail", "{% include 'body' %}")
    assert_result("header body body_detail footer", "{% include 'nested_template' %}")
  end

  test :nested_include_with_variable do
    assert_result(
      "Product: Draft 151cm details ",
      "{% include 'nested_product_template' with product %}",
      %{"product" => %{"title" => "Draft 151cm"}}
    )

    assert_result(
      "Product: Draft 151cm details Product: Element 155cm details ",
      "{% include 'nested_product_template' for products %}",
      %{"products" => [%{"title" => "Draft 151cm"}, %{"title" => "Element 155cm"}]}
    )
  end

  test :dynamic_include do
    assert_result(
      "Product: Draft 151cm details ",
      "{% include template with product %}",
      %{"product" => %{"title" => "Draft 151cm"}, "template" => "nested_product_template"}
    )
  end

  # test :recursively_included_template_does_not_produce_endless_loop do
  #   infinite_file_system = defmodule InfiniteFileSystem do
  #     def read_template_file(root, template_path, context) do
  #       "-{% include 'loop' %}"
  #     end
  #   end
  #   Liquid.FileSystem.register infinite_file_system
  #   t = Template.parse("{% include 'loop' %}")
  #   { :error, _ } = Template.render(t)
  # end

  # test :backwards_compatability_support_for_overridden_read_template_file do
  #   infinite_file_system = defmodule InfiniteFileSystem do
  #     def read_template_file(root, template_path, context) do
  #       "- hi mom"
  #     end
  #   end
  #   Liquid.FileSystem.register infinite_file_system
  #   t = Template.parse("{% include 'hi_mom' %}")
  #   { :ok, _ } = Template.render(t)
  # end

  # test :dynamically_choosen_template do
  #   assert_result "Test123", "{% include template %}", [template: "Test123"]
  #   assert_result "Test321", "{% include template %}", [template: "Test321"]

  #   assert_result "Product: Draft 151cm ",
  #                 "{% include template for product %}",
  #                 [template: "product", product: [title: "Draft 151cm"]]
  # end

  defp assert_result(expected, markup), do: assert_result(expected, markup, %Liquid.Context{})

  defp assert_result(expected, markup, %Liquid.Context{} = context) do
    t = Template.parse(markup)
    {:ok, rendered, _context} = Template.render(t, context)
    assert expected == rendered
  end

  defp assert_result(expected, markup, assigns) do
    context = %Liquid.Context{assigns: assigns}
    assert_result(expected, markup, context)
  end
end
