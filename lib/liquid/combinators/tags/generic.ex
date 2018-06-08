defmodule Liquid.Combinators.Tags.Generic do
  @moduledoc """
  Secondary tags used inside primary tags
  We defined a tag as secondary when it needs a primary tag to work
  For example, `else` tag is used by `if`, `for` and `cycle` but id doesn't
  work alone
  """
  alias Liquid.Combinators.Tag

  def else_tag, do: Tag.define_inverse_open("else")
end
