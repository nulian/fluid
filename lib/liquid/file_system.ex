defmodule Liquid.BlankFileSystem do
  def read_template_file(_root, _name, _context) do
    {:error, "This liquid context does not allow includes."}
  end
end

defmodule Liquid.LocalFileSystem do
  def read_template_file(_root, _name, _context) do
    {:ok, ""}
  end

  def full_path(root, template_path) do
    full_path =
      if Regex.match?(~r/\//, template_path) do
        root
        |> Path.join(template_path |> Path.dirname())
        |> Path.join("_#{template_path |> Path.basename()}.liquid")
      else
        root |> Path.join("_#{template_path}.liquid")
      end

    cond do
      !Regex.match?(~r/^[^.\/][a-zA-Z0-9_\/]+$/, template_path) ->
        {:error, "Illegal template name '#{template_path}'"}

      !Regex.match?(~r/^#{Path.expand(root)}/, Path.expand(full_path)) ->
        {:error, "Illegal template path '#{Path.expand(full_path)}'"}

      true ->
        {:ok, full_path}
    end
  end
end

defmodule Liquid.FileSystem do
  @moduledoc """
  Allows to set up the file system and read the template file from it
  """

  @doc """
  Get full file system path
  """
  def full_path(path, options) do
    case lookup(options) do
      nil -> {:error, "No file system defined"}
      {mod, root} -> mod.full_path(root, path)
    end
  end

  def read_template_file(path, options) do
    case lookup(options) do
      nil -> {:error, "No file system defined"}
      {mod, root} -> mod.read_template_file(root, path, options)
    end
  end

  def lookup(options) do
    Keyword.get(options, :file_system)
  end
end
