defmodule Liquid.Translators.Tags.For do
  @moduledoc """
  Translate new AST to old AST for the For tag.
  """

  alias Liquid.Block
  alias Liquid.Translators.{General, Markup}
  alias Liquid.NimbleTranslator
  alias Liquid.Combinators.Tags.For

  @doc """
  Takes the markup of the new AST, creates a `Liquid.Block` struct (old AST) and fill the keys needed to render a For tag.
  """
  @spec translate(For.markup()) :: Block.t()
  def translate(
        statements: [variable: variable, value: value, params: params],
        body: body,
        else: [body: else_body]
      ) do
    create_block_for(variable, value, params, body, else_body)
  end

  def translate(
        statements: [variable: variable, value: value, params: params],
        body: body
      ) do
    create_block_for(variable, value, params, body, [])
  end

  defp create_block_for(variable, value, params, body, else_body) do
    variable_markup = Markup.literal(variable)
    for_params_markup = Markup.literal(params)
    markup = "#{variable_markup} in #{Markup.literal(value)} #{for_params_markup}"

    %Liquid.Block{
      elselist: unwrap(NimbleTranslator.process_node(else_body)),
      iterator: process_iterator(%Block{markup: markup}),
      markup: markup,
      name: :for,
      nodelist: General.types_only_list(NimbleTranslator.process_node(body))
    }
  end

  defp process_iterator(%Block{markup: markup}) do
    Liquid.ForElse.parse_iterator(%Block{markup: markup})
  end

  defp unwrap([]), do: []
  defp unwrap([first | _]), do: first
  defp unwrap(element), do: element
end
