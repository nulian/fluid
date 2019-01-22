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
  alias Liquid.Combinators.{General, Tag}
  alias Liquid.Translators.Markup

  @type t :: [comment: Comment.markup()]

  @type markup :: [String.t() | Comment.t() | Raw.t()]

  @doc """
  Parses Comment content, creating a keyword list, the value of this list is the internal behaviour of the comment tag.
  """
  @spec comment_content() :: NimbleParsec.t()
  def comment_content do
    General.literal_until_tag()
    |> optional(
      choice([
        parsec(:comment) |> optional(parsec(:comment_content)),
        parsec(:raw) |> optional(parsec(:comment_content)),
        any_tag() |> optional(parsec(:comment_content))
      ])
    )
    |> concat(General.literal_until_tag())
  end

  @doc """
  Parses a `Liquid` Comment tag, creates a Keyword list where the key is the name of the tag
  (comment in this case) and the value is another keyword list which represents the internal
  structure of the tag.
  """
  @spec tag() :: NimbleParsec.t()
  def tag do
    Tag.define_closed(
      "comment",
      & &1,
      fn combinator ->
        combinator
        |> optional(parsec(:comment_content))
        |> reduce({Markup, :literal, []})
      end,
      ""
    )
  end

  @doc """
  Combinator that parse the syntax of a tag ({% anything_here %})but not of a valid `Liquid` tag.
  """
  @spec any_tag() :: NimbleParsec.t()
  def any_tag do
    empty()
    |> string(General.codepoints().start_tag)
    |> optional(repeat(General.whitespace()))
    |> choice([
      string_with_comment(),
      string_with_endcomment(),
      string_without_comment()
    ])
    |> reduce({List, :to_string, []})
    |> string(General.codepoints().end_tag)
  end

  @doc """
  Combinator that parse a string that can contain a "endcomment" string in it.
  """
  @spec string_with_endcomment() :: NimbleParsec.t()
  def string_with_endcomment do
    utf8_char([])
    |> concat(string_without_comment())
    |> concat(string("endcomment"))
    |> optional(string_without_comment())
  end

  @doc """
  Combinator that parse a string that can contain a "comment" string in it.
  """
  @spec string_with_comment() :: NimbleParsec.t()
  def string_with_comment do
    string_without_comment()
    |> concat(string("comment"))
    |> concat(string_without_comment())
  end

  @doc """
  Combinator that parse a string that can not contain a "comment" or "endcomment" string in it.
  """
  @spec string_without_comment() :: NimbleParsec.t()
  def string_without_comment do
    empty()
    |> repeat_until(utf8_char([]), [
      string(General.codepoints().start_tag),
      string(General.codepoints().end_tag),
      string("endcomment"),
      string("comment")
    ])
  end
end
