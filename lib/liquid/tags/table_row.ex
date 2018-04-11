defmodule Liquid.TableRow do
  @moduledoc """
  `tablerow` tag iterates over an array or collection splitting it up to a table with pre-set columns number
  Several useful variables are available to you within the loop.
  Generates an HTML table. Must be wrapped in opening <table> and closing </table> HTML tags.
  Input:
  ```
    <table>
    {% tablerow product in collection.products %}
    {{ product.title }}
    {% endtablerow %}
    </table>
  ```
  Output:
  ```
    <table>
    <tr class="row1">
      <td class="col1">
        Cool Shirt
      </td>
      <td class="col2">
        Alien Poster
      </td>
      <td class="col3">
        Batman Poster
      </td>
      <td class="col4">
        Bullseye Shirt
      </td>
      <td class="col5">
        Another Classic Vinyl
      </td>
      <td class="col6">
        Awesome Jeans
      </td>
    </tr>
    </table>
    ```
  """
  alias Liquid.{Block, Context, Expression, RangeLookup, Render, Template, Variable}

  defmodule Iterator do
    @moduledoc """
    Defines iteraction structs used by 'TableRow' in order to iterates over an list or collection.
    """
    defstruct name: nil,
              collection: nil,
              item: nil,
              cols: nil,
              limit: nil,
              offset: nil,
              forloop: %{}
  end

  @doc """
  Returns a regex for tag 'TableRow' expressions syntax validation
  """
  def syntax, do: ~r/(\w+)\s+in\s+(#{Liquid.quoted_fragment()}+)/

  @doc """
  Implementation of 'TableRaw' parse operations. Parses and organises markup to set up iterator
  """
  @spec parse(%Block{}, %Template{}) :: {%Block{}, %Template{}}
  def parse(%Block{nodelist: nodelist} = block, %Liquid.Template{} = t) do
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
    [[_, item | [orig_collection]]] = Regex.scan(syntax(), markup)
    collection = Expression.parse(orig_collection)
    attributes = Liquid.tag_attributes() |> Regex.scan(markup)
    limit = attributes |> parse_attribute("limit") |> Variable.create()
    offset = attributes |> parse_attribute("offset", "0") |> Variable.create()

    cols = attributes |> parse_attribute("cols", "0") |> Variable.create()

    %Iterator{
      name: orig_collection,
      item: item,
      collection: collection,
      limit: limit,
      offset: offset,
      cols: cols
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

  @doc """
  Implementation of 'TableRaw' render operations. Iterates through pre-set data and appends it to rendered output list
  Adds the HTML table rows and cols depending on the initial `cols` parameter
  """
  @spec render(list(), %Block{}, %Context{}) :: {list(), %Context{}}
  def render(output, %Block{iterator: it} = block, %Context{} = context) do
    {list, context} = parse_collection(it.collection, context)
    list = if is_binary(list) and list != "", do: [list], else: list

    if is_list(list) do
      {limit, context} = lookup_limit(it, context)
      {offset, context} = lookup_offset(it, context)
      {new_output, context} = each([], [make_ref(), limit, offset], list, block, context)
      {["</tr>\n" | [new_output | ["<tr class=\"row1\">\n"]]] ++ output, context}
    else
      if list == "" do
        {["</tr>\n", "<tr class=\"row1\">\n"] ++ output, context}
      else
        Render.render(output, block.elselist, context)
      end
    end
  end

  defp parse_collection(list, context) when is_list(list), do: {list, context}

  defp parse_collection(%Variable{} = variable, context), do: Variable.lookup(variable, context)

  defp parse_collection(%RangeLookup{} = range, context),
    do: {RangeLookup.parse(range, context), context}

  defp each(output, _, [], %Block{} = block, %Context{} = context),
    do: {output, remember_limit(block, context)}

  defp each(
         output,
         [prev, limit, offset],
         [h | t] = list,
         %Block{iterator: it} = block,
         %Context{assigns: assigns} = context
       ) do
    forloop = next_forloop(it, list, offset, limit)
    block = %{block | iterator: %{it | forloop: forloop}}

    assigns =
      assigns
      |> Map.put("tablerowloop", forloop)
      |> Map.put(it.item, h)
      |> Map.put("changed", {prev, h})

    {output_addition, block_context} = render_content(block, context, assigns, limit, offset)

    output = output_addition ++ output
    t = if block_context.break == true, do: [], else: t
    each(output, [h, limit, offset], t, block, %{context | assigns: block_context.assigns})
  end

  defp render_content(%Block{iterator: it} = block, context, assigns, limit, offset) do
    case {should_render?(limit, offset, it.forloop["index"]), block.blank} do
      {true, true} ->
        {_, new_context} = Render.render([], block.nodelist, %{context | assigns: assigns})
        {[], new_context}

      {true, _} ->
        {rendered, new_context} = Render.render([], block.nodelist, %{context | assigns: assigns})
        {rendered |> add_rows_data(it.forloop), new_context}

      _ ->
        {[], context}
    end
  end

  defp add_rows_data(output, forloop) do
    output = ["</td>"] ++ output ++ ["<td class=\"col#{forloop["col"]}\">"]

    if forloop["col_last"] and not forloop["last"],
      do: ["</tr>\n<tr class=\"row#{forloop["row"] + 1}\">"] ++ output,
      else: output
  end

  defp remember_limit(%Block{iterator: it}, context) do
    {rendered, context} = lookup_limit(it, context)
    limit = rendered || 0
    remembered = context.offsets[it.name] || 0
    %{context | offsets: context.offsets |> Map.put(it.name, remembered + limit)}
  end

  defp should_render?(_limit, offset, index) when index <= offset, do: false
  defp should_render?(nil, _, _), do: true
  defp should_render?(limit, offset, index) when index > limit + offset, do: false
  defp should_render?(_limit, _offset, _index), do: true

  defp lookup_limit(%Iterator{limit: limit}, %Context{} = context),
    do: Variable.lookup(limit, context)

  defp lookup_offset(%Iterator{offset: %Variable{name: "continue"}} = it, %Context{} = context),
    do: {context.offsets[it.name] || 0, context}

  defp lookup_offset(%Iterator{offset: offset}, %Context{} = context),
    do: Variable.lookup(offset, context)

  defp next_forloop(%Iterator{forloop: loop} = it, count, _, _) when map_size(loop) < 1 do
    count = count |> Enum.count()

    %{
      "name" => it.item <> "-" <> it.name,
      "index" => 1,
      "index0" => 0,
      "col" => 1,
      "col0" => 1,
      "row" => 1,
      "rindex" => count,
      "rindex0" => count - 1,
      "length" => count,
      "first" => true,
      "last" => count == 1,
      "col_first" => true,
      "col_last" => count == 1
    }
  end

  defp next_forloop(%Iterator{forloop: loop} = it, _count, offset, limit) do
    {new_col, col_last, row} = get_loop_indexes(loop, it.cols.literal, offset)

    new_loop = %{
      "name" => it.item <> "-" <> it.name,
      "index" => loop["index"] + 1,
      "index0" => loop["index0"] + 1,
      "col" => new_col,
      "col0" => loop["col0"] + 1,
      "row" => row,
      "rindex" => loop["rindex"] - 1,
      "rindex0" => loop["rindex0"] - 1,
      "length" => loop["length"],
      "first" => false,
      "last" => loop["rindex0"] == 1,
      "col_first" => new_col == 1,
      "col_last" => col_last
    }

    new_loop =
      if not is_nil(limit) and loop["index"] + 1 == limit + offset,
        do: %{new_loop | "last" => true},
        else: new_loop

    new_loop
  end

  defp get_loop_indexes(%{"index" => index} = loop, cols, offset)
       when index > offset and cols == 0 do
    {loop["col"] + 1, loop["rindex0"] == 1, 1}
  end

  defp get_loop_indexes(%{"index" => index} = loop, val, offset) when index > offset do
    remainder = rem(loop["col"], val)

    {remainder + 1, loop["rindex0"] == 1 or remainder == val - 1,
     div(loop["index"] - offset, val) + 1}
  end

  defp get_loop_indexes(loop, _cols, _offset), do: {loop["col"], false, loop["row"]}
end
