defmodule Liquid.Include do
  alias Liquid.Tag, as: Tag
  alias Liquid.Context, as: Context
  alias Liquid.Template, as: Template
  alias Liquid.Variable, as: Variable
  alias Liquid.FileSystem, as: FileSystem

  @compile {:inline, syntax: 0}
  def syntax,
    do:
      ~r/(#{Liquid.Parse.quoted_fragment()}+)(\s+(?:with|for)\s+(#{Liquid.Parse.quoted_fragment()}+))?/

  def parse(%Tag{markup: markup} = tag, %Template{} = template, _options) do
    [parts | _] = syntax() |> Regex.scan(markup)
    tag = parse_tag(tag, parts)
    attributes = parse_attributes(markup)
    {%{tag | attributes: attributes}, template}
  end

  defp parse_tag(%Tag{} = tag, parts) do
    case parts do
      [_, name] ->
        %{tag | parts: [name: name |> Variable.create()]}

      [_, name, " with " <> _, v] ->
        %{tag | parts: [name: name |> Variable.create(), variable: v |> Variable.create()]}

      [_, name, " for " <> _, v] ->
        %{tag | parts: [name: name |> Variable.create(), foreach: v |> Variable.create()]}
    end
  end

  defp parse_attributes(markup) do
    Liquid.Parse.tag_attributes()
    |> Regex.scan(markup)
    |> Enum.reduce(%{}, fn [_, key, val], coll ->
      Map.put(coll, key, val |> Variable.create())
    end)
  end

  def render(output, %Tag{parts: parts} = tag, %Context{} = context, options) do
    {file_system, root} = context |> Context.registers(:file_system) || FileSystem.lookup(options)

    {name, context} = parts[:name] |> Variable.lookup(context, options)

    source = load_template(root, name, context, file_system, options)

    source_hash = :crypto.hash(:md5, source) |> Base.encode16()

    cache_adapter = Keyword.get(options, :cache_adapter, Liquid.NoCacheAdapter)

    # todo: probably use options as a cache keys also?
    {_, t} =
      cache_adapter.fetch(:parsed_template, "parsed_template|#{source_hash}", fn _ ->
        Template.parse(source, %{}, name, options)
      end)

    if is_binary(t) do
      raise t
    end

    t = %{t | blocks: context.template.blocks ++ t.blocks}

    presets = build_presets(tag, context, options)

    assigns = context.assigns |> Map.merge(presets)

    cond do
      !is_nil(parts[:variable]) ->
        {item, context} =
          Variable.lookup(parts[:variable], %{context | assigns: assigns}, options)

        render_item(output, name, item, t, context, options)

      !is_nil(parts[:foreach]) ->
        {items, context} =
          Variable.lookup(parts[:foreach], %{context | assigns: assigns}, options)

        render_list(output, name, items, t, context, options)

      true ->
        render_item(output, name, nil, t, %{context | assigns: assigns}, options)
    end
  end

  defp load_template(root, name, context, file_system, options) do
    case file_system.read_template_file(root, name, context) do
      {:ok, source} ->
        source

      {:error, error_value} ->
        Keyword.get(options, :error_handler, Liquid.Prod.ErrorHandler).handle(error_value,
          name: name
        )
    end
  end

  defp build_presets(%Tag{} = tag, context, options) do
    tag.attributes
    |> Enum.reduce(%{}, fn {key, value}, coll ->
      {value, _} = Variable.lookup(value, context, options)
      Map.put(coll, key, value)
    end)
  end

  defp render_list(output, _, [], _, context, _options) do
    {output, context}
  end

  defp render_list(output, key, [item | rest], template, %Context{} = context, options) do
    {output, context} = render_item(output, key, item, template, context, options)
    render_list(output, key, rest, template, context, options)
  end

  defp render_item(output, _key, nil, template, %Context{} = context, options) do
    {:ok, rendered, _} = Template.render(template, context, options)
    {[rendered] ++ output, context}
  end

  defp render_item(output, key, item, template, %Context{} = context, options) do
    assigns = context.assigns |> Map.merge(%{key => item})

    {:ok, rendered, _} = Template.render(template, %{context | assigns: assigns}, options)
    {[rendered] ++ output, context}
  end
end
