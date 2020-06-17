defmodule Liquid.ForElse do
  @moduledoc """
     Like in Shopify's liquid: "For" iterates over an array or collection.
     Several useful variables are available to you within the loop.

     == Basic usage:
        {% for item in collection %}
          {{ forloop.index }}: {{ item.name }}
        {% endfor %}

     == Advanced usage:
        {% for item in collection %}
          <div {% if forloop.first %}class="first"{% endif %}>
            Item {{ forloop.index }}: {{ item.name }}
          </div>
        {% else %}
          There is nothing in the collection.
        {% endfor %}

     You can also define a limit and offset much like SQL.  Remember
     that offset starts at 0 for the first item.

        {% for item in collection limit:5 offset:10 %}
          {{ item.name }}
        {% end %}

      To reverse the for loop simply use {% for item in collection reversed %}

     == Available variables:

     forloop.name:: 'item-collection'
     forloop.length:: Length of the loop
     forloop.index:: The current item's position in the collection;
                     forloop.index starts at 1.
                     This is helpful for non-programmers who start believe
                     the first item in an array is 1, not 0.
     forloop.index0:: The current item's position in the collection
                      where the first item is 0
     forloop.rindex:: Number of items remaining in the loop
                      (length - index) where 1 is the last item.
     forloop.rindex0:: Number of items remaining in the loop
                       where 0 is the last item.
     forloop.first:: Returns true if the item is the first item.
     forloop.last:: Returns true if the item is the last item.
     forloop.parentloop:: Provides access to the parent loop, if present.

  """
  alias Liquid.Render
  alias Liquid.Block
  alias Liquid.Variable
  alias Liquid.Context
  alias Liquid.Expression
  alias Liquid.RangeLookup

  defmodule Iterator do
    defstruct name: nil,
              collection: nil,
              item: nil,
              reversed: false,
              limit: nil,
              offset: nil,
              forloop: %{}
  end

  @compile {:inline, syntax: 0}
  def syntax, do: ~r/(\w+)\s+in\s+(#{Liquid.Parse.quoted_fragment()}+)\s*(reversed)?/

  def parse(%Block{nodelist: nodelist} = block, %Liquid.Template{} = t, _options) do
    block = %{block | iterator: parse_iterator(block)}

    case Block.split(block) do
      {true_block, [_, false_block]} ->
        is_blank = Blank.blank?([true_block | false_block])
        {%{block | nodelist: true_block, elselist: false_block, blank: is_blank}, t}

      {_, []} ->
        is_blank = Blank.blank?(nodelist)
        {%{block | blank: is_blank}, t}
    end
  end

  defp parse_iterator(%Block{markup: markup}) do
    [[_, item | [orig_collection | reversed]]] = Regex.scan(syntax(), markup)
    collection = Expression.parse(orig_collection)
    reversed = !(reversed |> List.first() |> is_nil)
    attributes = Liquid.Parse.tag_attributes() |> Regex.scan(markup)
    limit = attributes |> parse_attribute("limit") |> Variable.create()
    offset = attributes |> parse_attribute("offset", "0") |> Variable.create()

    %Iterator{
      name: orig_collection,
      item: item,
      collection: collection,
      limit: limit,
      offset: offset,
      reversed: reversed
    }
  end

  defp parse_attribute(attributes, name, default \\ "nil") do
    attributes
    |> Enum.reduce(default, fn x, ret ->
      case x do
        [_, ^name, attribute] when is_binary(attribute) -> attribute
        _ -> ret
      end
    end)
  end

  def render(output, %Block{iterator: it} = block, %Context{} = context, options) do
    {list, context} = parse_collection(it.collection, context, options)

    list = if is_binary(list) and list != "", do: [list], else: list

    list = convert_to_list(list)

    if is_list(list) and !is_empty_list(list) do
      list = if it.reversed, do: Enum.reverse(list), else: list
      {limit, context} = lookup_limit(it, context, options)
      {offset, context} = lookup_offset(it, context, options)
      each(output, [make_ref(), limit, offset], list, block, context, options)
    else
      Render.render(output, block.elselist, context, options)
    end
  end

  defp convert_to_list(map) when is_map(map) do
    find_list_in_map(map)
  end

  defp convert_to_list(sth), do: sth

  defp find_list_in_map(map) when is_map(map) do
    key =
      map
      |> Map.keys()
      |> Enum.find(fn key -> is_list(Map.get(map, key)) end)

    Map.get(map, key, nil)
  end

  defp find_list_in_map(sth), do: sth

  defp is_empty_list([]), do: true
  defp is_empty_list(value) when is_list(value), do: false
  defp is_empty_list(_value), do: false

  defp parse_collection(list, context, _options) when is_list(list), do: {list, context}

  defp parse_collection(%Variable{} = variable, context, options) do
    Variable.lookup(variable, context, options)
  end

  defp parse_collection(%RangeLookup{} = range, context, options) do
    {RangeLookup.parse(range, context, options), context}
  end

  def each(output, _, [], %Block{} = block, %Context{} = context, options),
    do: {output, remember_limit(block, context, options)}

  def each(
        output,
        [prev, limit, offset],
        [h | t] = list,
        %Block{} = block,
        %Context{} = context,
        options
      ) do
    forloop = next_forloop(block.iterator, list)
    block = %{block | iterator: %{block.iterator | forloop: forloop}}

    assigns =
      context.assigns
      |> Map.put("forloop", forloop)
      |> Map.put(block.iterator.item, h)

    registers = context.registers |> Map.put("changed", {prev, h})

    {output, block_context} =
      render_content(
        output,
        block,
        %{context | assigns: assigns, registers: registers},
        [
          limit,
          offset
        ],
        options
      )

    t = if block_context.break == true, do: [], else: t

    each(
      output,
      [h, limit, offset],
      t,
      block,
      %{
        context
        | assigns: block_context.assigns,
          registers: block_context.registers
      },
      options
    )
  end

  defp render_content(
         output,
         %Block{iterator: %{forloop: %{"index" => index}}, nodelist: nodelist, blank: blank},
         context,
         [limit, offset],
         options
       ) do
    case {should_render?(limit, offset, index), blank} do
      {true, true} ->
        {_, new_context} = Render.render([], nodelist, context, options)
        {output, new_context}

      {true, _} ->
        Render.render(output, nodelist, context, options)

      _ ->
        {output, context}
    end
  end

  defp remember_limit(
         %Block{iterator: %{name: name} = it},
         %{offsets: offsets} = context,
         options
       ) do
    {rendered, context} = lookup_limit(it, context, options)
    limit = rendered || 0
    remembered = Map.get(offsets, name, 0)
    %{context | offsets: offsets |> Map.put(name, remembered + limit)}
  end

  defp should_render?(_limit, offset, index) when index <= offset, do: false
  defp should_render?(nil, _, _), do: true
  defp should_render?(limit, offset, index) when index > limit + offset, do: false
  defp should_render?(_limit, _offset, _index), do: true

  defp lookup_limit(%Iterator{limit: limit}, %Context{} = context, options),
    do: Variable.lookup(limit, context, options)

  defp lookup_offset(
         %Iterator{offset: %Variable{name: "continue"}, name: name},
         %Context{offsets: offsets} = context,
         _options
       ) do
    {Map.get(offsets, name, 0), context}
  end

  defp lookup_offset(%Iterator{offset: offset}, %Context{} = context, options),
    do: Variable.lookup(offset, context, options)

  defp next_forloop(%Iterator{forloop: loop, item: item, name: name}, count)
       when map_size(loop) < 1 do
    count = Enum.count(count)

    %{
      "name" => item <> "-" <> name,
      "index" => 1,
      "index0" => 0,
      "rindex" => count,
      "rindex0" => count - 1,
      "length" => count,
      "first" => true,
      "last" => count == 1
    }
  end

  defp next_forloop(
         %Iterator{
           forloop: %{
             "name" => name,
             "index" => index,
             "index0" => index0,
             "rindex" => rindex,
             "rindex0" => rindex0,
             "length" => length
           }
         },
         _count
       ) do
    %{
      "name" => name,
      "index" => index + 1,
      "index0" => index0 + 1,
      "rindex" => rindex - 1,
      "rindex0" => rindex0 - 1,
      "length" => length,
      "first" => false,
      "last" => rindex0 == 1
    }
  end
end

defmodule Liquid.Break do
  alias Liquid.Tag, as: Tag
  alias Liquid.Context, as: Context
  alias Liquid.Template, as: Template

  def parse(%Tag{} = tag, %Template{} = template, _options), do: {tag, template}

  def render(output, %Tag{}, %Context{} = context, _options) do
    {output, %{context | break: true}}
  end
end

defmodule Liquid.Continue do
  alias Liquid.Tag, as: Tag
  alias Liquid.Context, as: Context

  def parse(%Tag{} = tag, template, _options), do: {tag, template}

  def render(output, %Tag{}, %Context{} = context, _options) do
    {output, %{context | continue: true}}
  end
end

defmodule Liquid.IfChanged do
  alias Liquid.{Template, Block}

  def parse(%Block{} = block, %Template{} = t, _options), do: {block, t}

  def render(output, %Block{nodelist: nodelist}, context, options) do
    case context.registers["changed"] do
      {l, r} when l != r -> Liquid.Render.render(output, nodelist, context, options)
      _ -> {output, context}
    end
  end
end
