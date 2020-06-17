Code.require_file("../../test_helper.exs", __ENV__.file)

defmodule Liquid.BlockTest do
  use ExUnit.Case

  setup do
    start_supervised!({Liquid.Process, [name: :liquid]})
    :ok
  end

  defmodule TestBlock do
    def parse(b, p, _), do: {b, p}
  end

  defmodule TestTag do
    def parse(b, p, _), do: {b, p}
  end

  test "blankspace" do
    template = Liquid.parse_template(:liquid, "  ")
    assert template.root.nodelist == ["  "]
  end

  test "variable beginning" do
    template = Liquid.parse_template(:liquid, "{{funk}}  ")
    assert 2 == Enum.count(template.root.nodelist)
    assert [%Liquid.Variable{name: name}, <<string::binary>>] = template.root.nodelist
    assert name == "funk"
    assert string == "  "
  end

  test "variable end" do
    template = Liquid.parse_template(:liquid, "  {{funk}}")
    assert 2 == Enum.count(template.root.nodelist)
    assert [<<_::binary>>, %Liquid.Variable{name: name}] = template.root.nodelist
    assert name == "funk"
  end

  test "variable middle" do
    template = Liquid.parse_template(:liquid, "  {{funk}}  ")
    assert 3 == Enum.count(template.root.nodelist)
    assert [<<_::binary>>, %Liquid.Variable{name: name}, <<_::binary>>] = template.root.nodelist
    assert name == "funk"
  end

  test "variable many embedded fragments" do
    template = Liquid.parse_template(:liquid, "  {{funk}} {{so}} {{brother}} ")
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
    template = Liquid.parse_template(:liquid, "  {% comment %} {% endcomment %} ")
    assert 3 == Enum.count(template.root.nodelist)
    assert [<<_::binary>>, %Liquid.Block{}, <<_::binary>>] = template.root.nodelist
  end

  test "registering custom tags/blocks" do
    Liquid.register_tags(:liquid, "test", TestTag, Liquid.Tag)
    assert {TestTag, Liquid.Tag} = Liquid.registers_lookup(:liquid, "test")
  end

  test "with custom block" do
    Liquid.register_tags(:liquid, "testblock", TestBlock, Liquid.Block)
    template = Liquid.parse_template(:liquid, "{% testblock %}{% endtestblock %}")
    assert [%Liquid.Block{name: :testblock}] = template.root.nodelist
  end

  test "with custom tag" do
    Liquid.register_tags(:liquid, "testtag", TestTag, Liquid.Tag)
    template = Liquid.parse_template(:liquid, "{% testtag %}")
    assert [%Liquid.Tag{name: :testtag}] = template.root.nodelist
  end

  test "with multiline block" do
    template =
      Liquid.parse_template(:liquid, """
      {% include 'foo',
        foo: bar,
        bar: 'baz',
        baz: foo
      %}\
      """)

    assert 1 == Enum.count(template.root.nodelist)
  end
end
