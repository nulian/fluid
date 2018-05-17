defmodule Liquid.Combinators.Tags.Capture do
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

  def capture_sentences do
    empty()
    |> optional(parsec(:__parse__))
    |> tag(:capture_sentences)
  end

  @doc "Open capture tag: {% capture my_val %}"
  def open_tag do
    empty()
    |> parsec(:start_tag)
    |> ignore(string("capture"))
    |> concat(parsec(:variable_name))
    |> concat(parsec(:end_tag))
  end

  @doc "Close capture tag: {% endcapture %}"
  def close_tag do
    empty()
    |> parsec(:start_tag)
    |> ignore(string("endcapture"))
    |> concat(parsec(:end_tag))
  end

  def tag do
    empty()
    |> parsec(:open_tag_capture)
    |> optional(parsec(:capture_sentences))
    |> parsec(:close_tag_capture)
    |> tag(:capture)
    |> optional(parsec(:__parse__))
  end
end
