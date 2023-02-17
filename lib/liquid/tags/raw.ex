defmodule Liquid.Raw do
  alias Liquid.Template
  alias Liquid.Render
  alias Liquid.Block

  @compile {:inline, full_token_possibly_invalid: 0}
  def full_token_possibly_invalid,
    do: ~r/\A(.*)#{Liquid.Parse.tag_start()}\s*(\w+)\s*(.*)?#{Liquid.Parse.tag_end()}\z/m

  def parse(%Block{name: name} = block, [h | t], accum, %Template{} = template, options) do
    if Regex.match?(full_token_possibly_invalid(), h) do
      block_delimiter = "end" <> to_string(name)

      regex_result = Regex.scan(full_token_possibly_invalid(), h, capture: :all_but_first)

      [extra_data, endblock | _] = regex_result |> List.flatten()

      if block_delimiter == endblock do
        extra_accum = accum ++ [extra_data]
        block = %{block | strict: false, nodelist: extra_accum |> Enum.filter(&(&1 != ""))}
        {block, t, template}
      else
        if length(t) > 0 do
          parse(block, t, accum ++ [h], template, options)
        else
          raise "No matching end for block {% #{to_string(name)} %}"
        end
      end
    else
      parse(block, t, accum ++ [h], template, options)
    end
  end

  def parse(%Block{} = block, %Template{} = t, _options) do
    {block, t}
  end

  def render(output, %Block{} = block, context, options) do
    Render.render(output, block.nodelist, context, options)
  end
end
