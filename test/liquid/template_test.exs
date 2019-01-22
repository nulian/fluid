Code.require_file("../../test_helper.exs", __ENV__.file)

defmodule Liquid.TemplateTest do
  use ExUnit.Case

  alias Liquid.Template, as: Template

  setup_all do
    Liquid.start()
    :ok
  end

  test :should_be_able_to_handle_nil_in_parse do
    t = Template.parse(nil)
    assert {:ok, "", _context} = Template.render(t)
  end

  test :returns_assigns_from_assign_tags do
    t = Template.parse("{% assign foo = 'from returned assigns' %}{{ foo }}")
    {:ok, rendered, context} = Template.render(t)
    assert "from returned assigns" == rendered
    t = Template.parse("{{ foo }}")
    {:ok, rendered, _} = Template.render(t, context)
    assert "from returned assigns" == rendered
  end

  test :instance_assigns_persist_on_same_template_parsing_between_renders do
    t = Template.parse("{{ foo }}{% assign foo = 'foo' %}{{ foo }}")
    {:ok, rendered, context} = Template.render(t)
    assert "foo" == rendered
    {:ok, rendered, _} = Template.render(t, context)
    assert "foofoo" == rendered
  end

  test :custom_assigns_do_not_persist_on_same_template do
    t = Template.parse("{{ foo }}")

    {:ok, rendered, _} = Template.render(t, %{"foo" => "from custom assigns"})
    assert "from custom assigns" == rendered
    {:ok, rendered, _} = Template.render(t)
    assert "" == rendered
  end

  test :template_assigns_squash_assigns do
    t = Template.parse("{% assign foo = 'from instance assigns' %}{{ foo }}")
    {:ok, rendered, _} = Template.render(t)
    assert "from instance assigns" == rendered
    {:ok, rendered, _} = Template.render(t, %{"foo" => "from custom assigns"})
    assert "from instance assigns" == rendered
  end

  test :template_assigns_squash_preset_assigns do
    t =
      Template.parse("{% assign foo = 'from instance assigns' %}{{ foo }}", %{
        "foo" => "from preset assigns"
      })

    {:ok, rendered, _} = Template.render(t)
    assert "from instance assigns" == rendered
  end

  test "check if you can assign registers" do
    t = Template.parse("{{ foo }}")

    {:ok, rendered, context} =
      Template.render(t, %{"foo" => "from assigns"}, registers: %{test: "hallo"})

    assert "from assigns" == rendered
    assert %{test: "hallo"} == context.registers
  end
end
