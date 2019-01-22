defmodule Liquid.Translators.Tags.Tablerow do
  @moduledoc """
  Translate new AST to old AST for the Tablerow tag.
  """
  alias Liquid.{Block, NimbleTranslator, TableRow}
  alias Liquid.Translators.Markup
  alias Liquid.Combinators.Tags.Tablerow, as: TablerowMarkup

  @doc """
  Takes the markup of the new AST, creates a `Liquid.Block` struct (old AST) and fill the keys needed to render a Tablerow tag.
  """
  @spec translate(TablerowMarkup.markup()) :: Block.t()
  def translate(
        statements: [variable: variable, value: value, params: params],
        body: body
      ) do
    markup = "#{Markup.literal(variable)} in #{Markup.literal(value)} #{Markup.literal(params)}"

    %Liquid.Block{
      iterator: TableRow.parse_iterator(%Block{markup: markup}),
      markup: markup,
      name: :tablerow,
      nodelist: fixer_tablerow_types_only_list(NimbleTranslator.process_node(body))
    }
  end

  # fix current parser tablerow tag bug and compatibility
  defp fixer_tablerow_types_only_list(element) do
    if is_list(element), do: element, else: [element]
  end
end
