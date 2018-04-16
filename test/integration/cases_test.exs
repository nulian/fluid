defmodule Solid.Integration.CasesTest do
  use ExUnit.Case, async: true
  import Solid.Helpers

  @cases_dir "test/cases"
  @types ["simple", "medium", "complex"]

  @test_cases File.ls! "test/cases"
  for test_case <- @test_cases do
    for file <- File.ls! "test/cases/#{type}/#{test_case}/" do
      @external_resource "test/cases/#{type}/#{test_case}/#{file}"
    end
  end

  data    = "test/cases/db.json" |> File.read!() |> Poison.decode!()

  for test_case <- @test_cases do
    test "test case #{test_case}" do
      input_liquid  = File.read!("test/cases/#{unquote(test_case)}/input.liquid")
      expected_output = File.read!("test/cases/#{unquote(test_case)}/output.html")
      liquid_output    = render(input_liquid, data)
      {liquid_output, 0} = liquid_render(input_liquid, input_json)
      assert liquid_output == solid_output
    end
  end

  defp liquid_render(input_liquid, input_json) do
    System.cmd("ruby", ["test/liquid.rb", input_liquid, input_json])
  end
end
