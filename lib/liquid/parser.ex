defmodule Liquid.Parser do
  @moduledoc """
  Transform a valid liquid markup in an AST to be executed by `render`.
  """
  @inline true

  import NimbleParsec

  alias Liquid.Combinators.{General, LexicalToken}
  alias Liquid.Combinators.Tags.Generic
  alias Liquid.Ast

  alias Liquid.Combinators.Tags.{
    Assign,
    Comment,
    Decrement,
    EndBlock,
    Increment,
    Include,
    Raw,
    Cycle,
    If,
    For,
    Tablerow,
    Case,
    Capture,
    Ifchanged,
    CustomTag
  }

  @type t :: [
          Assign.t()
          | Capture.t()
          | Increment.t()
          | Decrement.t()
          | Include.t()
          | Cycle.t()
          | Raw.t()
          | Comment.t()
          | For.t()
          | If.t()
          | Unless.t()
          | Tablerow.t()
          | Case.t()
          | Ifchanged.t()
          | CustomTag.t()
          | CustomBlock.t()
          | General.liquid_variable()
          | String.t()
        ]

  defparsec(:variable_definition, General.variable_definition(), inline: @inline)
  defparsec(:variable_name, General.variable_name(), inline: @inline)
  defparsec(:variable_definition_for_assignment, General.variable_definition_for_assignment(), inline: @inline)
  defparsec(:filter, General.filter(), inline: @inline)
  defparsec(:filters, General.filters(), inline: @inline)
  defparsec(:comparison_operators, General.comparison_operators(), inline: @inline)
  defparsec(:condition, General.condition(), inline: @inline)
  defparsec(:logical_condition, General.logical_condition(), inline: @inline)

  defparsec(:value_definition, LexicalToken.value_definition(), inline: @inline)
  defparsec(:value, LexicalToken.value(), inline: @inline)
  defparsec(:number, LexicalToken.number(), inline: @inline)
  defparsec(:object_property, LexicalToken.object_property(), inline: @inline)
  defparsec(:variable_value, LexicalToken.variable_value(), inline: @inline)
  defparsec(:variable_part, LexicalToken.variable_part(), inline: @inline)

  defparsec(:cycle_values, Cycle.cycle_values(), inline: @inline)
  defparsec(:comment, Comment.tag(), inline: @inline)
  defparsec(:comment_content, Comment.comment_content(), inline: @inline)
  defparsecp(:raw, Raw.tag(), inline: @inline)
  defparsecp(:raw_content, Raw.raw_content(), inline: @inline)

  # The tag order affects the parser execution any change can break the app
  liquid_tag =
    choice([
      Raw.tag(),
      Comment.tag(),
      If.tag(),
      If.unless_tag(),
      For.tag(),
      Case.tag(),
      Capture.tag(),
      Tablerow.tag(),
      Cycle.tag(),
      Assign.tag(),
      Increment.tag(),
      Decrement.tag(),
      Include.tag(),
      Ifchanged.tag(),
      Generic.else_tag(),
      Case.when_tag(),
      If.elsif_tag(),
      For.break_tag(),
      For.continue_tag(),
      EndBlock.tag(),
      CustomTag.tag()
    ])

  defparsec(
    :__parse__,
    empty()
    |> choice([
      liquid_tag,
      General.liquid_variable(),
    ]), inline: @inline
  )

  @doc """
  Validates and parse liquid markup.
  """
  @spec parse(String.t()) :: {:ok | :error, any()}
  def parse(markup) do
    case Ast.build(markup, %{tags: []}, []) do
      {:ok, template, %{tags: []}, ""} ->
        {:ok, template}

      {:ok, _, %{tags: [unclosed | _]}, ""} ->
        {:error, "Malformed tag, open without close: '#{unclosed}'", ""}

      {:error, message, rest_markup} ->
        {:error, message, rest_markup}
    end
  end
end
