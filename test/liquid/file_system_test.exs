Code.require_file("../../test_helper.exs", __ENV__.file)

defmodule FileSystemTest do
  use ExUnit.Case

  test :default do
    start_supervised!({Liquid.Process, [name: :default]})
    Liquid.register_file_system(:default, Liquid.BlankFileSystem, "/")

    {:error, _reason} = Liquid.read_template_file(:default, "dummy", dummy: "smarty")
  end

  test :local do
    start_supervised!({Liquid.Process, [name: :local]})
    Liquid.register_file_system(:local, Liquid.LocalFileSystem, "/some/path")

    {:ok, path} = Liquid.full_path(:local, "mypartial")
    assert "/some/path/_mypartial.liquid" == path

    {:ok, path} = Liquid.full_path(:local, "dir/mypartial")
    assert "/some/path/dir/_mypartial.liquid" == path

    {:error, _reason} = Liquid.full_path(:local, "../dir/mypartial")

    {:error, _reason} = Liquid.full_path(:local, "/dir/../../dir/mypartial")

    {:error, _reason} = Liquid.full_path(:local, "/etc/passwd")
  end
end
