defmodule Liquid.BlankFileSystem do
  @moduledoc """
  A Liquid file system is a way to let your templates retrieve other templates for use with the include tag.
  You can implement subclasses that retrieve templates from the database, from the file system using
  a different path structure, you can provide them as hard-coded inline strings, or any manner that you see fit.
  You can add additional instance variables, arguments, or methods as needed.
  """
  def read_template_file(_root, _name, _context) do
    {:error, "This liquid context does not allow includes."}
  end
end

defmodule Liquid.LocalFileSystem do
  @moduledoc """
  Implements an abstract file system which retrieves template files, ie. with the template name
  prefixed with an underscore. The extension “.liquid” is also added.
  For security reasons, template paths are only allowed to contain letters, numbers, and underscore.
  """

  @doc """
  Retuns ok when reads a tamplate file
  """
  def read_template_file(_root, _name, _context) do
    {:ok, ""}
  end

  @doc """
  Creates a full path, joining the root and the template path, 
  also creates a error if you use a wrong template name or path
  """
  @spec full_path(String.t(), String.t()) :: {:ok | :error, String.t()}
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
  Looks in the `env` for a file system and creates a full path according to the file system module,
  if  `env` returns nill, response with an error map: no file system defined
  """
  @spec full_path(String.t()) :: {Atom.t(), String.t()} | nil
  def full_path(path) do
    case lookup() do
      nil -> {:error, "No file system defined"}
      {mod, root} -> mod.full_path(root, path)
    end
  end

  @doc """
  Looks in the `env` for a  file system and reads the template according to the file system module,
  if the `env` returns nill, response with an error map: no file system defined
  """
  @spec read_template_file(String.t(), list()) :: {Atom.t(), String.t()} | nil
  def read_template_file(path, options \\ []) do
    case lookup() do
      nil -> {:error, "No file system defined"}
      {mod, root} -> mod.read_template_file(root, path, options)
    end
  end

  @doc """
  Registers in the `env` , the module (file system module)  and the root path for the lookup
  """
  @spec register(String.t(), String.t()) :: %{}
  def register(module, path \\ "") do
    Application.put_env(:liquid, :file_system, {module, path})
  end

  @doc """
  Gets from the `env` the module(file system module) and the root path, to read the template and
  determine the file system(according to the file system module)
  """

  def lookup do
    Application.get_env(:liquid, :file_system)
  end
end
