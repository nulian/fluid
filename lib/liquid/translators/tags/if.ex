defmodule Liquid.Translators.Tags.If do
  @moduledoc """
  Translate new AST to old AST for the If tag.
  """
  alias Liquid.Translators.{General, Markup}
  alias Liquid.Combinators.Tags.If
  alias Liquid.{Block, IfElse, NimbleTranslator}

  @doc """
  Takes the markup of the new AST, creates a `Liquid.Block` struct (old AST) and fill the keys needed to render a If tag.
  """
  @spec translate(atom(), If.conditional_body()) :: Block.t()
  def translate(name, conditions: [value], body: body) when is_bitstring(value) do
    create_block_if(name, "\"#{Markup.literal(value)}\"", body)
  end

  def translate(name, [{:conditions, [value]}, {:body, body_parts} | elselist])
      when is_bitstring(value) do
    create_block_if(
      name,
      "\"#{Markup.literal(value)}\"",
      body_parts,
      normalize_elselist(elselist)
    )
  end

  def translate(name, conditions: conditions, body: body) do
    create_block_if(name, "#{Markup.literal(conditions)}", body)
  end

  def translate(name, [{:conditions, conditions}, {:body, body_parts} | elselist]) do
    create_block_if(
      name,
      "#{Markup.literal(conditions)}",
      body_parts,
      normalize_elselist(elselist)
    )
  end

  defp normalize_elselist([{:elsif, _} | [_]] = else_list) do
    {list, _} =
      Enum.reduce_while(else_list, {[], nil}, fn x, {list, last} ->
        case x do
          {:elsif, _} ->
            {:cont, {[x | list], x}}

          _ ->
            {tag, params} = last

            final_list =
              List.replace_at(
                list,
                length(list) - 1,
                {tag, Enum.reverse([x | Enum.reverse(params)])}
              )

            {:halt, {final_list, nil}}
        end
      end)

    list
  end

  defp normalize_elselist(else_list), do: else_list

  defp create_block_if(name, markup, nodelist) do
    block = %Liquid.Block{
      name: name,
      markup: markup,
      nodelist: nodelist |> NimbleTranslator.process_node() |> General.types_only_list(),
      blank: Blank.blank?(nodelist)
    }

    IfElse.parse_conditions(block)
  end

  defp create_block_if(name, markup, nodelist, else_list) do
    block = %Liquid.Block{
      name: name,
      markup: markup,
      nodelist: nodelist |> NimbleTranslator.process_node() |> General.types_only_list(),
      blank: Blank.blank?(nodelist) and Blank.blank?(else_list),
      elselist:
        else_list
        |> NimbleTranslator.process_node()
        |> List.flatten()
        |> General.types_only_list()
    }

    IfElse.parse_conditions(block)
  end
end
