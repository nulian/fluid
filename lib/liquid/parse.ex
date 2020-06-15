defmodule Liquid.Parse do
  alias Liquid.Template
  alias Liquid.Variable
  alias Liquid.Registers
  alias Liquid.Block

  def tokenize(<<string::binary>>) do
    Liquid.template_parser()
    |> Regex.split(string, on: :all_but_first, trim: true)
    |> List.flatten()
    |> Enum.filter(&(&1 != ""))
  end

  def parse(_, _, _)
  def parse(_, _, _, _, _)

  def parse("", %Template{} = template, options) do
    %{template | root: %Liquid.Block{name: :document}}
  end

  def parse(<<string::binary>>, %Template{} = template, options) do
    tokens = string |> tokenize
    name = tokens |> hd
    tag_name = parse_tag_name(name)
    tokens = parse_tokens(string, tag_name, options) || tokens
    {root, template} = parse(%Liquid.Block{name: :document}, tokens, [], template, options)
    %{template | root: root}
  end

  def parse(%Block{name: :document} = block, [], accum, %Template{} = template, _options) do
    unless nodelist_invalid?(block, accum), do: {%{block | nodelist: accum}, template}
  end

  def parse(
        %Block{name: :comment} = block,
        [h | t],
        accum,
        %Template{} = template,
        options
      ) do
    cond do
      Regex.match?(~r/{%\s*endcomment\s*%}/, h) ->
        {%{block | nodelist: accum}, t, template}

      Regex.match?(~r/{%\send.*?\s*$}/, h) ->
        raise "Unmatched block close: #{h}"

      true ->
        {result, rest, template} =
          try do
            parse_node(h, t, template, options)
          rescue
            # Ignore undefined tags inside comments
            RuntimeError ->
              {h, t, template}
          end

        parse(block, rest, accum ++ [result], template, options)
    end
  end

  def parse(%Block{name: name}, [], _, %Template{filename: filename}, _options) do
    raise "No matching end for block {% #{to_string(name)} %} in file: #{filename}"
  end

  def parse(%Block{name: name} = block, [h | t], accum, %Template{filename: filename} = template, options) do
    endblock = "end" <> to_string(name)

    cond do
      Regex.match?(~r/{%\s*#{endblock}\s*%}/, h) ->
        unless nodelist_invalid?(block, accum), do: {%{block | nodelist: accum}, t, template}

      Regex.match?(~r/{%\send.*?\s*$}/, h) ->
        raise "Unmatched block close: #{h} in file #{filename}"

      true ->
        {result, rest, template} = parse_node(h, t, template, options)
        parse(block, rest, accum ++ [result], template, options)
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

  defp parse_tokens(<<string::binary>>, tag_name, options) do
    case Registers.lookup(tag_name, options) do
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

  defp parse_tag_name(name) do
    case Regex.named_captures(Liquid.parser(), name) do
      %{"tag" => tag_name, "variable" => _} -> tag_name
      _ -> nil
    end
  end

  defp parse_node(<<name::binary>>, rest, %Template{} = template, options) do
    case Regex.named_captures(Liquid.parser(), name) do
      %{"tag" => "", "variable" => markup} when is_binary(markup) ->
        {Variable.create(markup), rest, template}

      %{"tag" => markup, "variable" => ""} when is_binary(markup) ->
        parse_markup(markup, rest, template, options)

      nil ->
        {name, rest, template}
    end
  end

  defp parse_markup(markup, rest, %Template{filename: filename} = template, options) do
    name = markup |> String.split(" ") |> hd |> String.trim()

    case Registers.lookup(name, options) do
      {mod, Liquid.Block} ->
        parse_block(mod, markup, rest, template, options)

      {mod, Liquid.Tag} ->
        tag = Liquid.Tag.create(markup)
        {tag, template} = mod.parse(tag, template, options)
        {tag, rest, template}

      nil ->
        raise "unregistered tag: #{name} in file: #{filename}"
    end
  end

  defp parse_block(mod, markup, rest, %Template{} = template, options) do
    block = Liquid.Block.create(markup)

    {block, rest, template} =
      try do
        mod.parse(block, rest, [], template)
      rescue
        UndefinedFunctionError -> parse(block, rest, [], template, options)
      end

    {block, template} = mod.parse(block, template, options)
    {block, rest, template}
  end
end
