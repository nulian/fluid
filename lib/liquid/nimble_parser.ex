defmodule Liquid.NimbleParser do
  import NimbleParsec

  defparsec(
    :extra_spaces,
    " "
    |> string()
    |> repeat()
    |> ignore()
  )

  defparsecp(
    :any,
    parsec(:extra_spaces)
    |> concat(ascii_string([?a..?z, ?A..?Z], min: 1))
    |> concat(parsec(:extra_spaces))
  )

  defparsec(
    :start_tag,
    concat(
      string("{%"),
      parsec(:extra_spaces)
    )
    |> ignore()
  )

  defparsec(
    :end_tag,
    concat(
      parsec(:extra_spaces),
      string("%}")
    )
    |> ignore()
  )

  defparsecp(:tag_if, string("if true"))
  defparsecp(:tag_end_if, string("endif"))

  defparsecp(
    :start_if,
    parsec(:start_tag)
    |> concat(parsec(:tag_if))
    |> concat(ignore(parsec(:end_tag)))
    |> ignore()
  )

  defparsecp(
    :end_if,
    parsec(:start_tag)
    |> concat(parsec(:tag_end_if))
    |> concat(ignore(parsec(:end_tag)))
    |> ignore()
  )

  defparsec(
    :if,
    parsec(:start_if)
    |> concat(parsec(:any))
    |> concat(parsec(:end_if))
    |> tag(:if)
  )

  defparsecp(:tag_for, string("for"))
  defparsecp(:tag_end_for, string("endfor"))

  defparsecp(
    :start_for,
    parsec(:start_tag)
    |> concat(parsec(:tag_for))
    |> concat(ignore(parsec(:end_tag)))
    |> ignore()
  )

  defparsecp(
    :end_for,
    parsec(:start_tag)
    |> concat(parsec(:tag_end_for))
    |> concat(ignore(parsec(:end_tag)))
    |> ignore()
  )

  defparsec(
    :for,
    parsec(:start_for)
    |> concat(parsec(:any))
    |> concat(parsec(:end_for))
    |> tag(:for)
  )
end
