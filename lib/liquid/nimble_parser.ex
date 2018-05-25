defmodule Liquid.NimbleParser do
  @moduledoc """
  Transform a valid liquid markup in an AST to be executed by `render`
  """
  import NimbleParsec

  alias Liquid.Combinators.{General, LexicalToken}
  alias Liquid.Combinators.Tags.{Assign, Decrement, Increment}

  defparsec(:liquid_object, General.liquid_object())
  defparsec(:variable_definition, General.variable_definition())
  defparsec(:variable_name, General.variable_name())
  defparsec(:start_tag, General.start_tag())
  defparsec(:end_tag, General.end_tag())
  defparsec(:filter_param, General.filter_param())
  defparsec(:filter, General.filter())
  defparsec(:single_quoted_token, General.single_quoted_token())
  defparsec(:double_quoted_token, General.double_quoted_token())
  defparsec(:quoted_token, General.quoted_token())
  defparsec(:comparison_operators, General.comparison_operators())
  defparsec(:logical_operators, General.logical_operators())
  defparsec(:comma_contition_value, General.comma_contition_value())
  defparsec(:ignore_whitespaces, General.ignore_whitespaces())

  defparsec(:number, LexicalToken.number())
  defparsec(:value_definition, LexicalToken.value_definition())
  defparsec(:value, LexicalToken.value())
  defparsec(:object_property, LexicalToken.object_property())
  defparsec(:boolean_value, LexicalToken.boolean_value())
  defparsec(:null_value, LexicalToken.null_value())
  defparsec(:string_value, LexicalToken.string_value())
  defparsec(:object_value, LexicalToken.object_value())
  defparsec(:variable_value, LexicalToken.variable_value())
  defparsec(:range_value, LexicalToken.range_value())

  defp clean_empty_strings(_rest, args, context, _line, _offset) do
    result =
      args
      |> Enum.filter(fn e -> e != "" end)

    {result, context}
  end

  defparsec(
    :__parse__,
    General.liquid_literal()
    |> optional(choice([parsec(:liquid_tag), parsec(:liquid_variable)]))
    |> traverse({:clean_empty_strings, []})
  )

  defparsec(:assign, Assign.tag())
  defparsec(:capture, Capture.tag())
  defparsec(:decrement, Decrement.tag())
  defparsec(:increment, Increment.tag())

  defparsec(
    :liquid_tag,
    choice([
      parsec(:assign),
      parsec(:capture),
      parsec(:increment),
      parsec(:decrement)
    ])
  )

  @doc """
  Validate and parse liquid markup.
  """
  @spec parse(String.t()) :: {:ok | :error, any()}
  def parse(""), do: {:ok, ""}

  def parse(markup) do
    case __parse__(markup) do
      {:ok, template, "", _, _, _} ->
        {:ok, template}

      {:ok, _, rest, _, _, _} ->
        {:error, "Error parsing: #{rest}"}
    end
  end
end
