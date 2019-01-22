defmodule Liquid.Combinators.Tags.Generic do
  @moduledoc """
  Secondary tags used inside primary tags.
  We defined a tag as secondary when it needs a primary tag to work.
  For example, `else` tag is used by `if`, `for` and `cycle` but id doesn't
  work alone
  """
  alias Liquid.Combinators.Tag

  @type else_tag :: [else: Liquid.NimbleParser.t()]

  @doc """
  Parses a `Liquid` Else tag, creates a Keyword list where the key is the name of the tag
  (else in this case) and the value is another keyword list which represent the internal
  structure of the tag.
  """
  @spec else_tag() :: NimbleParsec.t()
  def else_tag, do: Tag.define_sub_block("else", ["if", "unless", "case", "for"])
end
