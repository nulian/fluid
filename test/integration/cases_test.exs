defmodule Liquid.Test.Integration.CasesTest do
  use ExUnit.Case, async: true
  import Liquid.Helpers

  @cases_dir "test/integration/cases"
  @types ["simple", "medium", "complex"]
  @data "#{@cases_dir}/db.json"
        |> File.read!()
        |> Poison.decode!()

  for type <- @types do
    test_cases = File.ls!("#{@cases_dir}/#{type}")
    for test_case <- test_cases do
      test "case #{test_case}" do
        input_liquid = File.read!("#{@cases_dir}/#{type}/#{unquote(test_case)}/input.liquid")
        # expected_output = File.read!("#{@cases_dir}/#{type}/#{unquote(test_case)}/output.html")
        liquid_output = render(input_liquid, @data)
        assert liquid_output == ""
      end
    end
  end
end
