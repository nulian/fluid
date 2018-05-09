defmodule Liquid.Combinators.Tags.Comment do
  @moduledoc """
  Allows you to leave un-rendered code inside a Liquid template.
  Any text within the opening and closing comment blocks will not be output,
  and any Liquid code within will not be executed
  Input:
  ```
    Anything you put between {% comment %} and {% endcomment %} tags
    is turned into a comment.
  ```
  Output:
  ```
    Anything you put between  tags
    is turned into a comment
  ```
  """
  import NimbleParsec
  alias Liquid.Combinators.General

  @doc "Open comment tag: {% comment %}"
  def open_tag do
    empty()
    |> parsec(:start_tag)
    |> ignore(string("comment"))
    |> concat(parsec(:end_tag))
  end

  @doc "Close comment tag: {% endcomment %}"
  def close_tag do
    empty()
    |> parsec(:start_tag)
    |> ignore(string("endcomment"))
    |> concat(parsec(:end_tag))
  end

  def not_close_tag_comment do
    empty()
    |> ignore(utf8_char([]))
    |> parsec(:comment_content)
  end

  def comment_content do
    empty()
    |> repeat_until(utf8_char([]), [string(General.codepoints().start_tag)])
    |> choice([parsec(:close_tag_comment), parsec(:not_close_tag_comment)])
  end

  def tag do
    empty()
    |> parsec(:open_tag_comment)
    |> ignore(parsec(:comment_content))
    |> optional(parsec(:__parse__))
  end
end
