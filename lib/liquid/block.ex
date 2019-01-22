defmodule Liquid.Block do
  defstruct name: nil,
            markup: nil,
            condition: nil,
            parts: [],
            iterator: [],
            nodelist: [],
            elselist: [],
            blank: false,
            strict: true

  alias Liquid.Ast
  alias Liquid.Tag, as: Tag
  alias Liquid.Block, as: Block

  @type t :: %Liquid.Block{
          name: String.t() | nil,
          markup: String.t() | nil,
          condition: String.t() | nil,
          parts: [...],
          iterator: [...],
          nodelist: [...],
          elselist: [...],
          blank: boolean(),
          strict: boolean()
        }

  def create(markup) do
    destructure([name, rest], String.split(markup, " ", parts: 2))
    %Block{name: name |> String.to_atom(), markup: rest}
  end

  def split(nodes), do: split(nodes, [:else])
  def split(%Block{nodelist: nodelist}, namelist), do: split(nodelist, namelist)

  def split(nodelist, namelist) when is_list(nodelist) do
    Enum.split_while(nodelist, fn x ->
      !(is_map(x) and x.__struct__ == Tag and Enum.member?(namelist, x.name))
    end)
  end

  @doc """
  Build a liquid block (if, for, capture, case, unless, tablerow) with optional
  subblocks (else, when, elseif)
  """
  @spec build(binary(), {atom(), list()}, list(), list(), list(), list()) ::
          {:error, binary(), binary()} | {:ok, list(), list(), binary()}
  def build(markup, block, sub_blocks, bodies, context, ast),
    do: markup |> Ast.build(context, []) |> do_build(block, sub_blocks, bodies, ast)

  defp do_build(
         {:ok, [[{:sub_block, [sub_block]}] | body], context, rest},
         block,
         sub_blocks,
         bodies,
         ast
       ) do
    build(rest, block, [sub_block | sub_blocks], [body | bodies], context, ast)
  end

  defp do_build(
         {:ok, [[{:end_block, _}] | last_body], context, rest},
         block,
         sub_blocks,
         bodies,
         ast
       ),
       do: Ast.build(rest, context, [close(block, sub_blocks, bodies, last_body) | ast])

  defp do_build({:ok, acc, context, rest}, _, _, _, ast), do: {:ok, [acc | ast], context, rest}

  defp do_build({:error, error, rest}, _, _, _, _), do: {:error, error, rest}

  defp close({tag, body_block}, sub_blocks, bodies, last_body) do
    all_blocks = [body_block | do_close(sub_blocks, bodies, last_body, [])] |> List.flatten()
    {tag, all_blocks}
  end

  defp do_close([], [], last_body, all_blocks),
    do: [{:body, Enum.reverse(last_body)} | all_blocks]

  defp do_close([{sub_block, block_body} | sub_blocks], [body | bodies], current_body, all_blocks) do
    block_body = block_body |> Keyword.put(:body, Enum.reverse(current_body)) |> Enum.reverse()
    do_close(sub_blocks, bodies, body, [{sub_block, block_body} | all_blocks])
  end
end
