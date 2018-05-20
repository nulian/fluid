defmodule Liquid.Parse do
  alias Liquid.Template
  alias Liquid.Variable
  alias Liquid.Registers
  alias Liquid.Block

  def tokenize(<<markup::binary>>) do
    Liquid.template_parser()
    |> Regex.split(markup, on: :all_but_first, trim: true)
    |> List.flatten()
    |> Enum.filter(&(&1 != ""))
  end

  @spec parse(markup :: binary(), %Template{}) :: %Template{}
  def parse("", %Template{} = template) do
    %{template | root: %Liquid.Block{name: :document}}
  end

  @spec parse(markup :: binary(), %Template{}) :: %Template{}
  def parse(<<markup::binary>>, %Template{} = template) do
    [raw_tag_name | _rest] = tokens = tokenize(markup)
    tag_name = parse_tag_name(raw_tag_name)
    tokens = parse_tokens(markup, tag_name) || tokens
    {root, template} = do_parse(%Liquid.Block{name: :document}, tokens, [], template)
    %{template | root: root}
  end

  defp do_parse(%Block{name: :document} = block, [], accum, %Template{} = template) do
    unless nodelist_invalid?(block, accum), do: {%{block | nodelist: accum}, template}
  end

  defp do_parse(%Block{name: :comment} = block, [h | t], accum, %Template{} = template) do
    cond do
      Regex.match?(~r/{%\s*endcomment\s*%}/, h) ->
        {%{block | nodelist: accum}, t, template}

      Regex.match?(~r/{%\send.*?\s*$}/, h) ->
        raise "Unmatched block close: #{h}"

      true ->
        {result, rest, template} =
          try do
            parse_node(h, t, template)
          rescue
            # Ignore undefined tags inside comments
            RuntimeError ->
              {h, t, template}
          end

        do_parse(block, rest, accum ++ [result], template)
    end
  end

  defp do_parse(%Block{name: name}, [], _, _) do
    raise "No matching end for block {% #{to_string(name)} %}"
  end

  defp do_parse(%Block{name: name} = block, [h | t], accum, %Template{} = template) do
    endblock = "end" <> to_string(name)

    cond do
      Regex.match?(~r/{%\s*#{endblock}\s*%}/, h) ->
        unless nodelist_invalid?(block, accum), do: {%{block | nodelist: accum}, t, template}

      Regex.match?(~r/{%\send.*?\s*$}/, h) ->
        raise "Unmatched block close: #{h}"

      true ->
        {result, rest, template} = parse_node(h, t, template)
        do_parse(block, rest, accum ++ [result], template)
    end
  end

  defp invalid_expression?(expression) when is_binary(expression) do
    Regex.match?(Liquid.invalid_expression(), expression)
  end

  defp invalid_expression?(_), do: false

  defp nodelist_invalid?(block, nodelist) do
    case block.strict do
      true ->
        if Enum.any?(nodelist, &invalid_expression?(&1)) do
          raise Liquid.SyntaxError,
            message: "no match delimiters in #{block.name}: #{block.markup}"
        end

      false ->
        false
    end
  end

  def parse_tokens(<<string::binary>>, tag_name) do
    case Registers.lookup(tag_name) do
      {mod, Liquid.Block} ->
        try do
          mod.tokenize(string)
        rescue
          UndefinedFunctionError -> nil
        end

      _ ->
        nil
    end
  end

  def parse_tag_name(name) do
    case Regex.named_captures(Liquid.parser(), name) do
      %{"tag" => tag_name, "variable" => _} -> tag_name
      _ -> nil
    end
  end

  def parse_node(<<name::binary>>, rest, %Template{} = template) do
    case Regex.named_captures(Liquid.parser(), name) do
      %{"tag" => "", "variable" => markup} when is_binary(markup) ->
        {Variable.create(markup), rest, template}

      %{"tag" => markup, "variable" => ""} when is_binary(markup) ->
        parse_markup(markup, rest, template)

      nil ->
        {name, rest, template}
    end
  end

  def parse_markup(markup, rest, template) do
    name = markup |> String.split(" ") |> hd

    case Registers.lookup(name) do
      {mod, Liquid.Block} ->
        parse_block(mod, markup, rest, template)

      {mod, Liquid.Tag} ->
        tag = Liquid.Tag.create(markup)
        {tag, template} = mod.parse(tag, template)
        {tag, rest, template}

      nil ->
        raise "unregistered tag: #{name}"
    end
  end

  def parse_block(mod, markup, rest, template) do
    block = Liquid.Block.create(markup)

    {block, rest, template} =
      try do
        mod.parse(block, rest, [], template)
      rescue
        UndefinedFunctionError -> do_parse(block, rest, [], template)
      end

    {block, template} = mod.parse(block, template)
    {block, rest, template}
  end
end
