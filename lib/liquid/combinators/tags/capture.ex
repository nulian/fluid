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
  alias Liquid.Combinators.{Tag, General}

  @type t :: [capture: Capture.markup()]

  @type markup :: [
          variable_name: String.t(),
          body: Liquid.NimbleParser.t()
        ]

  @doc """
  Parses a `Liquid` Capture tag, creates a Keyword list where the key is the name of the tag
  (capture in this case) and the value is another keyword list which represent the internal
  structure of the tag.
  """
  @spec tag() :: NimbleParsec.t()
  def tag do
    Tag.define_block("capture", fn combinator ->
      choice(combinator, [
        General.quoted_variable_name(),
        General.variable_name()
      ])
    end)
  end
end
