defmodule Liquid.Parse do
  alias Liquid.Template
  alias Liquid.Variable
  alias Liquid.Registers
  alias Liquid.Block

  def tokenize(<<string::binary>>) do
    template_parser()
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

  def parse(
        %Block{name: name} = block,
        [h | t],
        accum,
        %Template{filename: filename} = template,
        options
      ) do
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

  @compile {:inline, argument_separator: 0}
  @compile {:inline, filter_argument_separator: 0}
  @compile {:inline, filter_quoted_string: 0}
  @compile {:inline, filter_quoted_fragment: 0}
  @compile {:inline, filter_arguments: 0}
  @compile {:inline, single_quote: 0}
  @compile {:inline, double_quote: 0}
  @compile {:inline, quote_matcher: 0}
  @compile {:inline, variable_start: 0}
  @compile {:inline, variable_end: 0}
  @compile {:inline, variable_incomplete_end: 0}
  @compile {:inline, tag_start: 0}
  @compile {:inline, tag_end: 0}
  @compile {:inline, any_starting_tag: 0}
  @compile {:inline, invalid_expression: 0}
  @compile {:inline, tokenizer: 0}
  @compile {:inline, parser: 0}
  @compile {:inline, template_parser: 0}
  @compile {:inline, partial_template_parser: 0}
  @compile {:inline, quoted_string: 0}
  @compile {:inline, quoted_fragment: 0}
  @compile {:inline, tag_attributes: 0}
  @compile {:inline, variable_parser: 0}
  @compile {:inline, filter_parser: 0}

  def argument_separator, do: ","
  def filter_argument_separator, do: ":"
  def filter_quoted_string, do: "\"[^\"]*\"|'[^']*'"

  def filter_quoted_fragment,
    do: "#{filter_quoted_string()}|(?:[^\s,\|'\":]|#{filter_quoted_string()})+"

  # (?::|,)\s*((?:\w+\s*\:\s*)?"[^"]*"|'[^']*'|(?:[^ ,|'":]|"[^":]*"|'[^':]*')+):?\s*((?:\w+\s*\:\s*)?"[^"]*"|'[^']*'|(?:[^ ,|'":]|"[^":]*"|'[^':]*')+)?
  def filter_arguments,
    do:
      ~r/(?:#{filter_argument_separator()}|#{argument_separator()})\s*((?:\w+\s*\:\s*)?#{filter_quoted_fragment()}):?\s*(#{filter_quoted_fragment()})?/

  def single_quote, do: "'"
  def double_quote, do: "\""
  def quote_matcher, do: ~r/#{single_quote()}|#{double_quote()}/

  def variable_start, do: "{{"
  def variable_end, do: "}}"
  def variable_incomplete_end, do: "\}\}?"

  def tag_start, do: "{%"
  def tag_end, do: "%}"

  def any_starting_tag, do: "(){{()|(){%()"

  def invalid_expression,
    do: ~r/^{%.*}}$|^{{.*%}$|^{%.*([^}%]}|[^}%])$|^{{.*([^}%]}|[^}%])$|(^{{|^{%)/ms

  def tokenizer,
    do: ~r/()#{tag_start()}.*?#{tag_end()}()|()#{variable_start()}.*?#{variable_end()}()/

  def parser,
    do:
      ~r/#{tag_start()}\s*(?<tag>.*?)\s*#{tag_end()}|#{variable_start()}\s*(?<variable>.*?)\s*#{variable_end()}/ms

  def template_parser, do: ~r/#{partial_template_parser()}|#{any_starting_tag()}/ms

  def partial_template_parser,
    do: "()#{tag_start()}.*?#{tag_end()}()|()#{variable_start()}.*?#{variable_incomplete_end()}()"

  def quoted_string, do: "\"[^\"]*\"|'[^']*'"
  def quoted_fragment, do: "#{quoted_string()}|(?:[^\s,\|'\"]|#{quoted_string()})+"

  def tag_attributes, do: ~r/(\w+)\s*\:\s*(#{quoted_fragment()})/
  def variable_parser, do: ~r/\[[^\]]+\]|[\w\-]+/
  def filter_parser, do: ~r/(?:\||(?:\s*(?!(?:\|))(?:#{quoted_fragment()}|\S+)\s*)+)/

  defp invalid_expression?(expression) when is_binary(expression) do
    Regex.match?(invalid_expression(), expression)
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
    case Regex.named_captures(parser(), name) do
      %{"tag" => tag_name, "variable" => _} -> tag_name
      _ -> nil
    end
  end

  defp parse_node(<<name::binary>>, rest, %Template{} = template, options) do
    case Regex.named_captures(parser(), name) do
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
        mod.parse(block, rest, [], template, options)
      rescue
        UndefinedFunctionError -> parse(block, rest, [], template, options)
      end

    {block, template} = mod.parse(block, template, options)
    {block, rest, template}
  end
end
