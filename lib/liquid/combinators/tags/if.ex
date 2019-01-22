defmodule Liquid.Combinators.Tags.If do
  @moduledoc """
  Executes a block of code only if a certain condition is true.
  If this condition is false executes `else` block of code.
  Input:
  ```
    {% if product.title == 'Awesome Shoes' %}
      These shoes are awesome!
    {% else %}
      These shoes are ugly!
    {% endif %}
  ```
  Output:
  ```
    These shoes are ugly!
  ```
  """
  alias Liquid.Combinators.{Tag, General}

  @type t :: [if: conditional_body()]
  @type unless_tag :: [unless: conditional_body()]
  @type conditional_body :: [
          conditions: General.conditions(),
          body: [
            Liquid.NimbleParser.t()
            | [elsif: conditional_body()]
            | [else: Liquid.NimbleParser.t()]
          ]
        ]

  @doc """
  Parses a `Liquid` If tag, creates a Keyword list where the key is the name of the tag
  (if in this case) and the value is another keyword list which represent the internal
  structure of the tag.
  """
  @spec tag() :: NimbleParsec.t()
  def tag, do: do_tag("if")

  @doc """
  Parses a `Liquid` Unless tag, creates a Keyword list where the key is the name of the tag
  (unless in this case) and the value is another keyword list, that represent the internal
  structure of the tag.
  """
  @spec unless_tag() :: NimbleParsec.t()
  def unless_tag, do: do_tag("unless")

  @doc """
  Parses a `Liquid` Elsif tag, creates a Keyword list where the key is the name of the tag
  (elsif in this case) and the value is the result of the `body_elsif()` combinator.
  """
  @spec elsif_tag() :: NimbleParsec.t()
  def elsif_tag, do: Tag.define_sub_block("elsif", ["if", "unless"], &General.conditions/1)

  defp do_tag(name) do
    Tag.define_block(name, &General.conditions/1)
  end
end
