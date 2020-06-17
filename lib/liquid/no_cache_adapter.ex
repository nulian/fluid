defmodule Liquid.NoCacheAdapter do
  def fetch(_name, _key, fun), do: {:ok, fun.(nil)}
end
