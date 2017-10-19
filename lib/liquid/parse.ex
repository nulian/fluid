defmodule Liquid.Parse do
  alias Liquid.Template
  alias Liquid.Variable
  alias Liquid.Registers
  alias Liquid.Block

  def tokenize(<<string::binary>>) do
    Liquid.template_parser
      |> Regex.split(string, on: :all_but_first, trim: true)
      |> List.flatten
      |> Enum.filter(&(&1 != ""))
  end

  def parse_new(ast, template) do
    { root, template } = parse_new(%Liquid.Block{name: :document}, ast, [], template)
    %{template | root: root}
  end

  def parse_new(%Block{name: :document} = block, [], accum, %Template{} = template) do
    { %{ block | nodelist: Enum.reverse(accum) }, template }
  end

  def parse_new(%Block{name: :comment}=block, [h|t], accum, %Template{}=template) do
    case h do
      %Block{name: :comment, end_marker: true} ->
        { %{ block | nodelist: Enum.reverse(accum) }, t, template }
      %Block{end_marker: true} ->
        raise "Unmatched block close: #{h}"
      h ->
        { result, rest, template } = try do
          parse_node(h, t, template)
        rescue
          # Ignore undefined tags inside comments
          RuntimeError -> { h, t, template }
        end
        parse_new(block, rest, [result] ++ accum, template)
    end
  end

  def parse_new(%Block{name: name, end_marker: false}, [], _, _) do
    raise "No matching end for block {% #{to_string(name)} %}"
  end

  def parse_new(%Block{} = block, [h|t], accum, %Template{}=template) do
    case h do
      %Block{end_marker: true} ->
        { %{ block | nodelist: Enum.reverse(accum) }, t, template }
      _ ->
        { result, rest, template } = parse_node_new(h, t, template)
        parse_new(block, rest, [result] ++ accum, template)
    end
  end

  defp parse_node_new(head, tail, %Template{}=template) do
    case head do
      %Variable{} ->
        { head, tail, template }
      %type{} when type in [Tag, Block] ->
        parse_struct_node_new(head, tail, template)
      _ -> { head, tail, template }
    end
  end

  defp parse_struct_node_new(%{name: name} = head, tail, %Template{} = template) do
    case Registers.lookup(name) do
      { mod, Liquid.Block } ->
        parse_block_new(mod, head, tail, template)
      { mod, Liquid.Tag } ->
        tag = Liquid.Tag.create(head)
        { tag, template } = mod.parse(tag, template)
        { tag, tail, template }
      nil -> raise "unregistered tag: #{name}"
    end
  end

  defp parse_block_new(mod, head, rest, template) do
    { head, rest, template } = try do
      mod.parse(head, rest, [], template)
    rescue
      UndefinedFunctionError -> parse_new(head, rest, [], template)
    end
    { head, template } = mod.parse(head, template)
    { head, rest, template }
  end

  def parse("", %Template{}=template) do
    %{template | root: %Liquid.Block{name: :document}}
  end

  def parse(<<string::binary>>, %Template{}=template) do
    tokens = string |> tokenize
    name = tokens |> hd
    tag_name = parse_tag_name(name)
    tokens = parse_tokens(string, tag_name) || tokens
    { root, template } = parse(%Liquid.Block{name: :document}, tokens, [], template)
    %{ template | root: root }
  end

  def parse(%Block{name: :document}=block, [], accum, %Template{}=template) do
    { %{ block | nodelist: accum }, template }
  end

  def parse(%Block{name: :comment}=block, [h|t], accum, %Template{}=template) do
    cond do
      Regex.match?(~r/{%\s*endcomment\s*%}/, h) ->
        { %{ block | nodelist: accum }, t, template }
      Regex.match?(~r/{%\send.*?\s*$}/, h) ->
        raise "Unmatched block close: #{h}"
      true ->
        { result, rest, template } = try do
          parse_node(h, t, template)
        rescue
          # Ignore undefined tags inside comments
          RuntimeError -> { h, t, template }
        end
        parse(block, rest, accum ++ [result], template)
    end
  end

  def parse(%Block{name: name}, [], _, _) do
    raise "No matching end for block {% #{to_string(name)} %}"
  end

  def parse(%Block{name: name}=block, [h|t], accum, %Template{}=template) do
    endblock = "end" <> to_string(name)
    cond do
      Regex.match?(~r/{%\s*#{endblock}\s*%}/, h) ->
        { %{ block | nodelist: accum }, t, template }
      Regex.match?(~r/{%\send.*?\s*$}/, h) ->
        raise "Unmatched block close: #{h}"
      true ->
        { result, rest, template } = parse_node(h, t, template)
        parse(block, rest, accum ++ [result], template)
    end
  end

  defp parse_tokens(<<string::binary>>, tag_name) do
    case Registers.lookup(tag_name) do
      {mod, Liquid.Block} ->
        try do
          mod.tokenize(string)
        rescue
          UndefinedFunctionError -> nil
        end
      _ -> nil
    end
  end


  defp parse_tag_name(name) do
    case Regex.named_captures(Liquid.parser, name) do
      %{"tag" => tag_name, "variable" => _ } -> tag_name
      _ -> nil
    end
  end

  defp parse_node(<<name::binary>>, rest, %Template{}=template) do
    case Regex.named_captures(Liquid.parser, name) do
      %{"tag" => "", "variable" => markup} when is_binary(markup) ->
        { Variable.create(markup), rest, template }
      %{"tag" => markup, "variable" => ""} when is_binary(markup) ->
        parse_markup(markup, rest, template)
      nil -> { name, rest, template }
    end
  end

  defp parse_markup(markup, rest, template) do
    name = markup |> String.split(" ") |> hd
    case Registers.lookup(name) do
      { mod, Liquid.Block } ->
        parse_block(mod, markup, rest, template)
      { mod, Liquid.Tag } ->
        tag = Liquid.Tag.create(markup)
        { tag, template } = mod.parse(tag, template)
        { tag, rest, template }
      nil -> raise "unregistered tag: #{name}"
    end
  end

  defp parse_block(mod, markup, rest, template) do
    block = Liquid.Block.create(markup)
    { block, rest, template } = try do
        mod.parse(block, rest, [], template)
      rescue
        UndefinedFunctionError -> parse(block, rest, [], template)
      end
    { block, template } = mod.parse(block, template)
    { block, rest, template }
  end

end
