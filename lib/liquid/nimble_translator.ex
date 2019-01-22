defmodule Liquid.NimbleTranslator do
  @moduledoc """
  Translate NimbleParser AST to old AST.
  """
  alias Liquid.Template

  alias Liquid.Translators.Tags.{
    Assign,
    Break,
    Capture,
    Case,
    Comment,
    Continue,
    Cycle,
    Decrement,
    For,
    If,
    Ifchanged,
    Include,
    Increment,
    LiquidVariable,
    Raw,
    Tablerow,
    CustomTag
  }

  @doc """
  Converts Nimble AST into old AST in order to use old render.
  """
  def translate({:ok, [""]}) do
    %Template{root: %Liquid.Block{name: :document}}
  end

  def translate({:ok, [literal_text]}) when is_bitstring(literal_text) do
    %Template{root: %Liquid.Block{name: :document, nodelist: [literal_text]}}
  end

  def translate({:ok, nodelist}) when is_list(nodelist) do
    list = process_node(nodelist)
    %Template{root: %Liquid.Block{name: :document, nodelist: list}}
  end

  @doc """
  Takes the new parsed tag and match it with his translator, then return the old parser struct.
  """
  @spec process_node(Liquid.NimbleParser.t()) :: Liquid.Tag.t() | Liquid.Block.t()
  def process_node(elem) when is_bitstring(elem), do: elem

  def process_node([elem]) when is_bitstring(elem), do: elem

  def process_node(nodelist) when is_list(nodelist) do
    Enum.map(nodelist, &process_node/1)
  end

  def process_node({tag, markup}) do
    translated =
      case tag do
        :liquid_variable ->
          LiquidVariable.translate(markup)

        :assign ->
          Assign.translate(markup)

        :capture ->
          Capture.translate(markup)

        :comment ->
          Comment.translate(markup)

        :cycle ->
          Cycle.translate(markup)

        :decrement ->
          Decrement.translate(markup)

        :for ->
          For.translate(markup)

        :if ->
          If.translate(:if, markup)

        :unless ->
          If.translate(:unless, markup)

        :elsif ->
          If.translate(:if, markup)

        :else ->
          [body: body_parts] = markup
          process_node(body_parts)

        :include ->
          Include.translate(markup)

        :increment ->
          Increment.translate(markup)

        :tablerow ->
          Tablerow.translate(markup)

        :ifchanged ->
          Ifchanged.translate(markup)

        :raw ->
          Raw.translate(markup)

        :break ->
          Break.translate(markup)

        :continue ->
          Continue.translate(markup)

        :case ->
          Case.translate(markup)

        :custom ->
          CustomTag.translate(markup)
      end

    check_blank(translated)
  end

  @doc """
  Emulates the `Liquid` behavior for blanks blocks. Checks all the blocks and determine if it is blank or not.
  """
  @spec check_blank(Liquid.Tag.t() | Liquid.Block.t()) :: Liquid.Tag.t() | Liquid.Block.t()
  def check_blank(%Liquid.Block{name: :if, nodelist: nodelist, elselist: elselist} = translated)
      when is_list(nodelist) and is_list(elselist) do
    if Blank.blank?(nodelist) and Blank.blank?(elselist) do
      %{translated | blank: true}
    else
      translated
    end
  end

  def check_blank(%Liquid.Block{nodelist: nodelist} = translated)
      when is_list(nodelist) do
    if Blank.blank?(nodelist) do
      %{translated | blank: true}
    else
      translated
    end
  end

  def check_blank(translated), do: translated
end
