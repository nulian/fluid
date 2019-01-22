defmodule Liquid.Combinators.Tags.Ifchanged do
  @moduledoc """
  The block contained within ifchanged will only be rendered to the output if the last call to ifchanged returned different output.

  Here is an example:

  <h1>Product Listing</h1>
  {% for product in products %}
    {% ifchanged %}<h3>{{ product.created_at | date:"%w" }}</h3>{% endifchanged %}
    <p>{{ product.title }} </p>
     ...
  {% endfor %}
  """
  alias Liquid.Combinators.Tag

  @doc """
  Parses a `Liquid` IfChanged tag, creates a Keyword list where the key is the name of the tag
  (ifchanged in this case) and the value is another keyword list which represent the internal
  structure of the tag.
  """
  @spec tag() :: NimbleParsec.t()
  def tag, do: Tag.define_block("ifchanged", & &1, "")
end
