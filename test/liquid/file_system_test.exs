Code.require_file("../../test_helper.exs", __ENV__.file)

defmodule FileSystemTest do
  use ExUnit.Case

  alias Liquid.FileSystem, as: FileSystem

  test :default do
    FileSystem.register(Liquid.BlankFileSystem, "/")
    {:error, _reason} = FileSystem.read_template_file("dummy", dummy: "smarty")
  end

  test :local do
    FileSystem.register(Liquid.LocalFileSystem, "/some/path")

    {:ok, path} = FileSystem.full_path("mypartial")
    assert "/some/path/_mypartial.liquid" == path

    {:ok, path} = FileSystem.full_path("dir/mypartial")
    assert "/some/path/dir/_mypartial.liquid" == path

    {:error, _reason} = FileSystem.full_path("../dir/mypartial")

    {:error, _reason} = FileSystem.full_path("/dir/../../dir/mypartial")

    {:error, _reason} = FileSystem.full_path("/etc/passwd")
  end
end
