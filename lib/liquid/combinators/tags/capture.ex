defmodule Liquid.Combinators.Tags.Capture do
  @moduledoc """
  Stores the result of a block into a variable without rendering it in place.
  ```
    {% capture heading %}
      Monkeys!
    {% endcapture %}
    ...
    <h1>{{ heading }}</h1> <!-- then you can use the `heading` variable -->
  ```
  Capture is useful for saving content for use later in your template, such as in a sidebar or footer.
  """

  import NimbleParsec
  alias Liquid.Combinators.Tag

  def tag do
    Tag.define(
      "capture",
      fn combinator -> parsec(combinator, :variable_name) end,
      "endcapture",
      fn combinator -> optional(combinator, parsec(:__parse__) |> tag(:capture_sentences)) end
    )
  end
end
