defmodule Liquid.Combinators.Tags.CustomTag do
  @moduledoc """
  Implementation of custom tag. "Tags" are tags that take any number of arguments, but do not contain a block of template code.
  To create a new tag, Use Liquid.Register module and register your tag with Liquid.Register.register/3.
  The register tag  takes three arguments: the user-facing name of the tag, the module where code of parsing/rendering is located
  and the type that implements it (tag or block).

  ```
    {% MyCustomTag argument1 = 1, argument2, argument3 = 5 %}
  ```

  """
  import NimbleParsec
  alias Liquid.Combinators.General

  @type t :: [custom_tag: Custom_tag.markup()]
  @type markup :: [custom_name: String.t(), custom_markup: [String.t()]]

  @doc """
  Parses a `Liquid` Custom tag, creates a Keyword list where the key is the name of the custom tag
  (custom_tag in this case) and the value is another keyword list which represent the internal
  structure of the tag (arguments).
  """
  @spec tag() :: NimbleParsec.t()
  def tag do
    General.start_tag()
    |> concat(General.valid_tag_name())
    |> optional(markup())
    |> concat(General.end_tag())
    |> traverse({__MODULE__, :check_customs, []})
  end

  def check_customs(_rest, [params | tag], %{tags: tags} = context, _line, _offset) do
    [tag_name] = tag
    name = String.to_atom(tag_name)

    Application.get_env(:liquid, :extra_tags, %{})
    |> Map.get(name)
    |> case do
      nil ->
        {[
           error:
             "Error processing tag '#{tag}'. It is malformed or you are creating a custom '#{tag}' without register it"
         ], context}

      {_, Liquid.Block} ->
        {[block: [custom: [{:custom_name, tag}, params]]], %{context | tags: [tag_name | tags]}}

      {_, Liquid.Tag} ->
        {[custom: [{:custom_name, tag}, params]], context}
    end
  end

  defp markup do
    empty()
    |> concat(General.ignore_whitespaces())
    |> concat(valid_markup())
    |> reduce({List, :to_string, []})
    |> unwrap_and_tag(:custom_markup)
  end

  defp valid_markup do
    repeat_until(utf8_char([]), [string("{%"), string("%}"), string("{{"), string("}}")])
  end
end
