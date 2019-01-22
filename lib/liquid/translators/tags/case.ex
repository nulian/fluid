defmodule Liquid.Translators.Tags.Case do
  @moduledoc """
  Translate new AST to old AST for the Case tag.
  """
  alias Liquid.Translators.Markup
  alias Liquid.Combinators.Tags.Case
  alias Liquid.{NimbleTranslator, Block, Variable, Case}

  @doc """
  Takes the markup of the new AST, creates a `Liquid.Block` struct (old AST) and fill the keys needed to render a Case tag.
  """
  @spec translate(Case.markup()) :: Block.t()
  def translate([condition, {:body, _} | when_list]) do
    to_case_block(Markup.literal(condition), Enum.flat_map(when_list, &process_clauses/1))
  end

  defp process_clauses({:when, [condition, body: values]}) do
    tag = %Liquid.Tag{
      name: :when,
      markup: Markup.literal(condition)
    }

    result = NimbleTranslator.process_node(values)
    [tag, result]
  end

  defp process_clauses({:else, [body: values]}) do
    process_list = NimbleTranslator.process_node(values)

    else_liquid_tag = %Liquid.Tag{name: :else}

    if is_list(process_list) do
      [else_liquid_tag | process_list]
    else
      [else_liquid_tag, process_list]
    end
  end

  defp to_case_block(markup, nodelist) do
    [[_, name]] = Regex.scan(Case.syntax(), markup)
    Case.split(Variable.create(name), nodelist)
  end
end
