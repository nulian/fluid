defmodule Liquid.Translators.Tags.CustomTag do
  @moduledoc """
  Translates new AST to old AST for the Custom tag.
  """
  alias Liquid.{Template, Tag, Block}
  alias Liquid.Translators.General

  @doc """
  Takes the markup of the new AST, creates a `Liquid.Tag` struct (old AST) and fill the keys needed to render a Custom tag.
  """
  @spec translate(Custom_tag.markup()) :: Tag.t()
  def translate(custom_name: [name], custom_markup: markup) do
    tag_name = String.to_atom(name)
    custom_tag = Application.get_env(:liquid, :extra_tags)

    case is_map(custom_tag) do
      true ->
        case Map.has_key?(custom_tag, tag_name) do
          true ->
            partial_tag = %Tag{
              name: String.to_atom(name),
              markup: String.trim(markup)
            }

            user_parse(partial_tag, custom_tag, tag_name)

          false ->
            raise Liquid.SyntaxError, message: "This custom tag: {% #{name} %} is not registered"
        end

      false ->
        raise Liquid.SyntaxError, message: "This custom tag: {% #{name} %} is not registered"
    end
  end

  def translate(custom_name: [name], custom_markup: markup, body: body) do
    tag_name = String.to_atom(name)
    custom_tags = Application.get_env(:liquid, :extra_tags)

    nodelist =
      body
      |> Liquid.NimbleTranslator.process_node()
      |> General.types_only_list()

    partial_block = %Block{
      name: tag_name,
      markup: String.trim(markup),
      nodelist: nodelist
    }

    user_parse(partial_block, custom_tags, tag_name)
  end

  defp user_parse(partial_block, map_of_tags, tag_name) do
    {module, _type} = Map.get(map_of_tags, tag_name)
    {block, _contex} = module.parse(partial_block, %Template{})
    block
  end
end
