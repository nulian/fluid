defmodule Liquid.Raw do
  @moduledoc """
  Temporarily disables tag processing. This is useful for generating content (eg, Mustache, Handlebars) which uses conflicting syntax.
  Input:
  ```
    {% raw %}
    In Handlebars, {{ this }} will be HTML-escaped, but
    {{{ that }}} will not.
    {% endraw %}
  ```
  Output:
  ```
  In Handlebars, {{ this }} will be HTML-escaped, but {{{ that }}} will not.
  ```
  """
  alias Liquid.{Block, Render, Template}

  @full_token_possibly_invalid ~r/\A(.*)#{Liquid.tag_start()}\s*(\w+)\s*(.*)?#{Liquid.tag_end()}\z/m

  @doc """
  Implementation of 'Raw' parse operations
  """

  def parse(%Block{name: name}, [], _, _),
    do: raise("No matching end for block {% #{to_string(name)} %}")

  @spec parse(%Block{}, any(), %Template{}) :: {%Block{}, %Template{}}
  def parse(%Block{name: name} = block, [h | t], accum, %Template{} = template) do
    if Regex.match?(@full_token_possibly_invalid, h) do
      block_delimiter = "end" <> to_string(name)

      regex_result = Regex.scan(@full_token_possibly_invalid, h, capture: :all_but_first)

      [extra_data, endblock | _] = List.flatten(regex_result)

      if block_delimiter == endblock do
        extra_accum = accum ++ [extra_data]
        block = %{block | strict: false, nodelist: Enum.filter(extra_accum, &(&1 != ""))}
        {block, t, template}
      else
        parse(block, t, accum ++ [h], template)
      end
    else
      parse(block, t, accum ++ [h], template)
    end
  end

  def parse(%Block{} = block, %Template{} = t) do
    {block, t}
  end

  @doc """
  Implementation of 'Raw' render operations
  """
  @spec render(list(), %Block{}, %Contex{}) :: {list(), %Contex{}}
  def render(output, %Block{} = block, context) do
    Render.render(output, block.nodelist, context)
  end
end
