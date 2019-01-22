defmodule Liquid.Ast do
  @moduledoc """
  Builds the AST processing with Nimble, only liquid valid tags and variables. It uses Tokenizer
  to send to Nimble only tags and variables, without literals.
  Literals (any markup which is not liquid variable or tag) are slow to be processed by Nimble thus
  this module improve performance between 30% and 100% depending how much text is processed.
  """
  alias Liquid.{Tokenizer, Parser, Block}

  @doc """
  Recursively builds the AST taking a markup, or a tuple with a literal and a rest markup.
  It uses `context` to validate the correct opening and close of blocks and sub blocks.
  """
  @spec build(binary() | {binary(), binary()}, Keyword.t(), list()) ::
          {:ok, list(), Keyword.t(), binary()} | {:error, binary(), binary()}
  def build({literal, ""}, context, ast), do: {:ok, Enum.reverse([literal | ast]), context, ""}
  def build({"", markup}, context, ast), do: parse_liquid(markup, context, ast)
  def build({literal, markup}, context, ast), do: parse_liquid(markup, context, [literal | ast])
  def build("", context, ast), do: {:ok, Enum.reverse(ast), context, ""}
  def build(markup, context, ast), do: markup |> Tokenizer.tokenize() |> build(context, ast)

  @spec build({:error, binary(), binary()}) :: {:error, binary(), binary()}
  def build({:error, error_message, rest_markup}), do: {:error, error_message, rest_markup}

  defp parse_liquid(markup, context, ast),
    do: markup |> Parser.__parse__(context: context) |> do_parse_liquid(ast)

  defp do_parse_liquid({:ok, [{:error, message}], rest, _, _, _}, _), do: {:error, message, rest}
  defp do_parse_liquid({:ok, [{:block, _}], _, _, _, _} = liquid, ast), do: block(liquid, ast)

  defp do_parse_liquid({:ok, [{:sub_block, _}] = tag, rest, context, _, _}, ast),
    do: {:ok, [tag | ast], context, rest}

  defp do_parse_liquid({:ok, [{:end_block, [{_, [tag]}]}], rest, %{tags: []}, _, _}, _),
    do: {:error, "The tag '#{tag}' was not opened", rest}

  defp do_parse_liquid(
         {:ok, [{:end_block, [{_, [tag_name]}]}] = tag, rest,
          %{tags: [last_tag | tags]} = context, _, _},
         ast
       )
       when tag_name == last_tag do
    {:ok, [tag | ast], %{context | tags: tags}, rest}
  end

  defp do_parse_liquid({:ok, [{:end_block, _}], rest, %{tags: [last_tag | _]}, _, _}, _),
    do: {:error, "The '#{last_tag}' tag has not been correctly closed", rest}

  defp do_parse_liquid({:ok, [tags], rest, context, _, _}, ast),
    do: build(rest, context, [tags | ast])

  defp do_parse_liquid({:error, message, rest, _, _, _}, _), do: {:error, message, rest}

  defp block({:ok, [{:block, [tag]}], markup, context, _, _}, ast),
    do: Block.build(markup, tag, [], [], context, ast)
end
