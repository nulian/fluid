defmodule Liquid.SyntaxError do
  @moduledoc """
  Error module to hold wrong syntax states
  """
  defexception message: "Liquid syntax error has occurred."
end

defmodule Liquid.FileSystemError do
  @moduledoc """
  Error module to hold file system errors.
  """
  defexception message: "Liquid error: Illegal template name"
end
