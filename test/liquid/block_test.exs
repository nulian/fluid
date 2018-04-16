Code.require_file("../../test_helper.exs", __ENV__.file)

defmodule Liquid.BlockTest do
  use ExUnit.Case

  defmodule TestBlock do
    def parse(b, p), do: {b, p}
  end

  defmodule TestTag do
    def parse(b, p), do: {b, p}
  end

  setup_all do
    Liquid.start()
    :ok
  end

  test "blankspace" do
    template = Liquid.Template.parse("  ")
    assert template.root.nodelist == ["  "]
  end

  test "variable beginning" do
    template = Liquid.Template.parse("{{funk}}  ")
    assert 2 == Enum.count(template.root.nodelist)
    assert [%Liquid.Variable{name: name}, <<string::binary>>] = template.root.nodelist
    assert name == "funk"
    assert string == "  "
  end

  test "variable end" do
    template = Liquid.Template.parse("  {{funk}}")
    assert 2 == Enum.count(template.root.nodelist)
    assert [<<_::binary>>, %Liquid.Variable{name: name}] = template.root.nodelist
    assert name == "funk"
  end

  test "variable middle" do
    template = Liquid.Template.parse("  {{funk}}  ")
    assert 3 == Enum.count(template.root.nodelist)
    assert [<<_::binary>>, %Liquid.Variable{name: name}, <<_::binary>>] = template.root.nodelist
    assert name == "funk"
  end

  test "variable many embedded fragments" do
    template = Liquid.Template.parse("  {{funk}} {{so}} {{brother}} ")
    assert 7 == Enum.count(template.root.nodelist)

    assert [
             <<_::binary>>,
             %Liquid.Variable{},
             <<_::binary>>,
             %Liquid.Variable{},
             <<_::binary>>,
             %Liquid.Variable{},
             <<_::binary>>
           ] = template.root.nodelist
  end

  test "with block" do
    template = Liquid.Template.parse("  {% comment %} {% endcomment %} ")
    assert 3 == Enum.count(template.root.nodelist)
    assert [<<_::binary>>, %Liquid.Block{}, <<_::binary>>] = template.root.nodelist
  end

  test "registering custom tags/blocks" do
    Liquid.Registers.register("test", TestTag, Liquid.Tag)
    assert {TestTag, Liquid.Tag} = Liquid.Registers.lookup("test")
  end

  test "with custom block" do
    Liquid.Registers.register("testblock", TestBlock, Liquid.Block)
    template = Liquid.Template.parse("{% testblock %}{% endtestblock %}")
    assert [%Liquid.Block{name: :testblock}] = template.root.nodelist
  end

  test "with custom tag" do
    Liquid.Registers.register("testtag", TestTag, Liquid.Tag)
    template = Liquid.Template.parse("{% testtag %}")
    assert [%Liquid.Tag{name: :testtag}] = template.root.nodelist
  end
end
